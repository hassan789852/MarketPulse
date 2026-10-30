import XCTest

@MainActor
final class MarketPulseUITests: XCTestCase {
    private func launch(failure: Bool = false, extraArguments: [String] = []) -> XCUIApplication {
        // Device orientation outlives an application process. Establish the next
        // test's geometry before calculating or synthesizing any touch locations.
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchArguments += extraArguments
        if failure { app.launchArguments.append("--ui-test-failure") }
        app.launch()
        XCTAssertTrue(element("watchlist", in: app).waitForExistence(timeout: 8))
        waitForOrientation(in: app, landscape: false)
        return app
    }

    func testLaunchCatalogSortingAndDetails() {
        let app = launch()
        XCTAssertTrue(element("watchlist.count", in: app).label.contains("25"))
        XCTAssertTrue(app.buttons["feed.start"].firstMatch.isEnabled)
        XCTAssertFalse(app.buttons["feed.stop"].firstMatch.isEnabled)
        app.segmentedControls.buttons["Price change"].tap()
        let direction = app.buttons["sort.direction"].firstMatch
        XCTAssertEqual(direction.value as? String, "Descending")
        direction.tap()
        XCTAssertEqual(direction.value as? String, "Ascending")
        let row = element("stock.AAPL", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        row.tap()
        XCTAssertTrue(element("details.ticker", in: app).waitForExistence(timeout: 4))
        XCTAssertEqual(element("details.ticker", in: app).label, "AAPL")
        XCTAssertEqual(element("details.company", in: app).label, "Apple")
        XCTAssertEqual(element("details.price", in: app).label, "$189.42")
        attachScreenshot(app, name: "Details — deterministic reference price")
    }

    func testStartStopAndSharedQuote() {
        let app = launch()
        app.segmentedControls.buttons["Price change"].tap()
        XCTAssertTrue(element("stock.AAPL", in: app).waitForExistence(timeout: 8))
        element("stock.AAPL", in: app).tap()
        XCTAssertTrue(element("details.price", in: app).waitForExistence(timeout: 4))
        let initial = element("details.price", in: app).label
        app.buttons["feed.start"].firstMatch.tap()
        let changed = NSPredicate(format: "label != %@", initial)
        expectation(for: changed, evaluatedWith: element("details.price", in: app))
        waitForExpectations(timeout: 8)
        XCTAssertTrue(app.buttons["feed.stop"].firstMatch.isEnabled)
        let price = element("details.price", in: app).label
        app.buttons["feed.stop"].firstMatch.tap()
        let stopped = NSPredicate(format: "enabled == true")
        expectation(for: stopped, evaluatedWith: app.buttons["feed.start"].firstMatch)
        waitForExpectations(timeout: 4)
        XCTAssertFalse(app.buttons["feed.stop"].firstMatch.isEnabled)
        XCTAssertEqual(element("details.price", in: app).label, price)
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if !element("stock.AAPL", in: app).isHittable && back.exists { back.tap() }
        let row = findRow("AAPL", app: app)
        XCTAssertTrue(row.label.contains(price))
        attachScreenshot(app, name: "Stopped — shared received quote")
    }

    func testConnectionFailureRemainsHonestAndRetryable() {
        let app = launch(failure: true)
        app.buttons["feed.start"].firstMatch.tap()
        let status = element("connection.status", in: app)
        let failed = NSPredicate(format: "value == %@", "Disconnected")
        expectation(for: failed, evaluatedWith: status)
        waitForExpectations(timeout: 6)
        XCTAssertTrue(app.buttons["feed.start"].firstMatch.isEnabled)
        XCTAssertFalse(app.buttons["feed.stop"].firstMatch.isEnabled)
        XCTAssertTrue(element("feed.explanation", in: app).label.contains("Unable to connect"))
        attachScreenshot(app, name: "Disconnected — reference prices retained")
    }

    func testLandscapePreservesSelectedSymbol() {
        let app = launch()
        app.segmentedControls.buttons["Price change"].tap()
        XCTAssertTrue(element("stock.AAPL", in: app).waitForExistence(timeout: 8))
        element("stock.AAPL", in: app).tap()
        XCTAssertTrue(element("details.ticker", in: app).waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        defer {
            XCUIDevice.shared.orientation = .portrait
            waitForOrientation(in: app, landscape: false)
        }
        // Selection can exist before the rotation animation finishes. Verify the actual
        // content geometry before claiming landscape coverage or capturing evidence.
        waitForOrientation(in: app, landscape: true)
        XCTAssertEqual(element("details.ticker", in: app).label, "AAPL")
        XCTAssertEqual(element("details.company", in: app).label, "Apple")
        XCTAssertTrue(element("details.price", in: app).isHittable)
        attachScreenshot(app, name: "Landscape — preserved AAPL selection")
    }

    func testLargeDynamicTypeKeepsControlsAccessible() {
        let app = launch(extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let start = app.buttons["feed.start"].firstMatch
        XCTAssertTrue(start.isHittable)
        XCTAssertGreaterThanOrEqual(start.frame.height, 44)
        start.tap()
        let stop = app.buttons["feed.stop"].firstMatch
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: stop)
        waitForExpectations(timeout: 8)
        XCTAssertTrue(stop.isHittable)
        stop.tap()
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: start)
        waitForExpectations(timeout: 8)
        attachScreenshot(app, name: "Accessibility Dynamic Type — reachable controls")
    }

    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }
    private func waitForOrientation(in app: XCUIApplication, landscape: Bool) {
        let geometryMatches = NSPredicate { _, _ in
            MainActor.assumeIsolated {
                let frame = app.frame
                return landscape ? frame.width > frame.height : frame.height > frame.width
            }
        }
        expectation(for: geometryMatches, evaluatedWith: app)
        waitForExpectations(timeout: 8)
    }
    private func findRow(_ symbol: String, app: XCUIApplication) -> XCUIElement {
        let row = element("stock.\(symbol)", in: app)
        for _ in 0..<12 {
            if row.exists && row.isHittable { return row }
            element("watchlist", in: app).swipeUp()
        }
        return row
    }
    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

import Foundation
import Testing
@testable import MarketPulse

struct PresentationTests {
    @MainActor @Test func listAndDetailsShareTheSameObservableQuoteWithoutConnectingAgain() async throws {
        let transport = FakeTransport(autoOpen: true)
        let repository = LiveMarketRepository(transportFactory: { transport }, generator: PriceGenerator(random: SeededRandomSource(seed: 42)), clock: ManualFeedClock())
        let store = MarketStore(repository: repository)
        let observation = Task { await store.observe() }
        defer { observation.cancel() }
        let detail = try #require(store.row(for: "AAPL"))
        #expect(detail === store.rows[0])
        store.selection = "AAPL"
        await store.start()
        try await eventually { await transport.sent.count == 1 }
        let data = try #require(await transport.sent.first)
        #expect(detail.quote.price == StockCatalog.stocks[0].referencePrice)
        await transport.deliver(data)
        try await eventually { await MainActor.run { store.receivedCount == 1 } }
        #expect(detail.quote.price == store.sortedRows.first { $0.id == "AAPL" }?.quote.price)
        #expect(detail.quote.price == (try Price(MessageCodec.decode(data).price)))
        #expect(store.state == .connected)
        #expect(await transport.connectCount == 1)
        store.sort = StockSort(metric: .change, direction: .ascending)
        #expect(store.selection == "AAPL")
        await store.stop()
        try await eventually { await MainActor.run { store.state == .stopped } }
        #expect(!store.wantsRunning)
    }

    @Test func localeAwareMonetaryFormattingAndSemanticDirection() throws {
        let locale = Locale(identifier: "en_US")
        #expect(MarketFormatting.price(Decimal(string: "189.42")!, locale: locale) == "$189.42")
        #expect(MarketFormatting.percent(Decimal(string: "0.014")!, locale: locale) == "+1.40%")
        #expect(MarketFormatting.signedPrice(-2, locale: locale) == "-$2.00")
        #expect(MarketFormatting.percent(0, locale: locale) == "0.00%")
        let quote = StockQuote(stock: StockCatalog.stocks[0], price: try Price("200"))
        #expect(MarketFormatting.voiceOver(quote, locale: locale).contains("up"))
        #expect(MarketFormatting.voiceOver(quote, locale: locale).contains("simulated"))
        #expect(MarketFormatting.price(123, locale: Locale(identifier: "ar_AE")) != MarketFormatting.price(123, locale: locale))
    }

    @Test func backoffIsBoundedAndJittered() {
        let policy = FeedPolicy()
        #expect(policy.retryDelay(attempt: 1, jitterPercent: 100) == .seconds(1))
        #expect(policy.retryDelay(attempt: 2, jitterPercent: 100) == .seconds(2))
        #expect(policy.retryDelay(attempt: 99, jitterPercent: 125) == .seconds(20))
        #expect(policy.retryDelay(attempt: 3, jitterPercent: 75) == .seconds(3))
    }
}

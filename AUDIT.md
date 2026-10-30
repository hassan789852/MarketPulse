# Final engineering audit

This is the historical 2026-10-29 audit. Subsequent publication and CI verification are tracked at the top of [VALIDATION.md](VALIDATION.md); statements about unpublished Git state below refer to the audit date.

**Revision note:** this report and its checksums describe the audit snapshot. A later user-requested button-alignment correction changed `FeedControls`, the shared theme and one color asset. Its separate Release/UI verification and current screenshots are recorded in [VALIDATION.md](VALIDATION.md) and [the screenshot index](Docs/Screenshots/README.md).

**Completed 2026-10-29. Verdict: ready for assessment review and an initial local commit, with the verification limits below.** No confirmed P0/P1 functional defect was found. Production Swift code, resources and Xcode configuration were preserved. Nothing was published, no remote was added, and the unrelated Flutter project was not modified.

The audit inspected source and test assertions, reran builds/tests, operated the normal Release app, inspected all 12 original screenshots, and used a separate read-only code reviewer. Previous documentation was treated as a claim, not proof.

## Findings and fixes

| Severity | Finding | Resolution |
|---|---|---|
| P0 / P1 | No reproducible functional defect found in the audited paths. | No speculative production or UI changes. |
| P2 — test evidence | The old Stop-during-handshake fake consumed its continuation on close, so the later `open()` did not deliver an actual successful late completion. Duplicate Start counted connections but not overlapping receives. | Strengthened the existing test with a deliberately cancellation-insensitive handshake. Added restart-before-old-handshake and repeated-Start tests, with receive concurrency and exact send-count assertions. |
| P2 — visual evidence | The old landscape test asserted selection without waiting for landscape geometry; its attachment was cropped/partly black. The old failure screenshot showed percentage truncation already fixed in source. | Added landscape geometry and price-hittability assertions. Captured a full landscape framebuffer from the normal Release app. Refreshed the failure screenshot and corrected the screenshot index. |
| P2 — documentation | License/attribution status was unstated. The architecture diagram published Stopped after close, while source publishes it before awaiting close. | Added `NOTICES.md` without granting an unrequested license; corrected the diagram and clarified evidence boundaries. |

Changed code files are limited to `MarketPulseTests/TestDoubles.swift`, `MarketPulseTests/RepositoryTests.swift` and `MarketPulseUITests/MarketPulseUITests.swift`. Other changes are documentation, evidence summaries and real screenshots. There are now **27 unit-test functions and 5 UI tests**.

## Architecture and WebSocket verification

- **Echo-only publication:** `LiveMarketRepository.prepareMessage` generates/registers candidates without mutating quotes. `accept` is the only production quote-application path, after `EchoValidator.accept` succeeds. The integration test asserts unchanged price/count after send, then a changed quote only after explicit echo delivery.
- **Real handshake:** normal composition uses exactly `wss://ws.postman-echo.com/raw`. Transport `connect()` completes only after `URLSessionWebSocketDelegate.didOpenWithProtocol`. Calling `resume()` cannot publish Connected. The opening timeout is 12 seconds.
- **Single ownership:** one repository actor owns quotes, validation ledger, session and task handles. One transport is created per attempt. Start is guarded; receive/production begin after handshake. New assertions observed at most one concurrent receive and one candidate per manual tick despite repeated Start.
- **Stop/retry:** Stop clears intent, invalidates session/retry identity, cancels tasks and publishes Stopped before awaiting close. Every old callback/retry checks identity and intent. New tests complete the old handshake after Stop and after a replacement connection; neither produces old-session work nor disturbs the replacement.
- **Failure policy:** one retry task closes the prior attempt before bounded exponential backoff with jitter. Five retries are allowed; accepted echoes reset the budget. An independent watchdog covers missing echoes even during suspended send. Existing tests cover finite retries, background intent, interrupted receive, silent connections, suspended send and repository release.
- **Integrity:** payload size, schema/type, known symbol, strict positive Decimal, session/message IDs, increasing sequence, timestamp age and exact registered-message equality are checked. Duplicates, unsolicited payloads, stale sessions, older sequences and malformed frames cannot mutate quotes. Pending entries and history are bounded.
- **Shared UI:** MainActor `MarketStore` exposes stable `QuoteModel` references to both screens. Tests assert object identity and shared updated values; opening details creates no transport/generator. Selection and sort state live above navigation columns.
- **Money:** authoritative calculations use Decimal, bounded positive values and bankers' cent rounding. Percentage change uses fictional seed references. All sort directions use ticker tie-breaking. Formatting is locale-aware USD/percent, with semantic arrows/VoiceOver text. Double is confined to chart coordinates.
- **Concurrency:** actors, weak captures, cancellation and teardown were reviewed. Complete Swift 6 strict-concurrency compilation passes. Lifetime tests cover suspended I/O. No detached task, timer-driven visible-price bypass, unsafe mutable application singleton or extra details feed was found. This is not an Instruments performance certification.

## Original 17 requirements

| # | Requirement | Independent result/evidence |
|---|---|---|
| 1 | At least 25 scrollable symbols | PASS — exact catalog test, UI count, actual list |
| 2 | Company/ticker/price/change | PASS — source and Release captures |
| 3 | Required real WebSocket | PASS — endpoint, production diagnostic, Release interaction |
| 4 | Client randomized updates | PASS — generator bounds, deterministic/fairness tests |
| 5 | Send via WebSocket | PASS — production send path and real echoes |
| 6 | Receive echoes | PASS — 75 newly validated server echoes |
| 7 | Publish only validated echoes | PASS — mutation trace and send-before-echo regression |
| 8 | Sort by price | PASS — both directions and UI control |
| 9 | Sort by change | PASS — signed percentage, ties and changed values |
| 10 | Selection/details navigation | PASS — UI test and normal Release interaction |
| 11 | Detail quote/change/description | PASS — source, screenshots and assertions |
| 12 | Shared real-time state | PASS — same-object presentation test and UI value comparison |
| 13 | Visible accurate status | PASS — handshake gate, failure test and real Connecting/Connected/Stopped observations |
| 14 | Start/Stop controls | PASS — cancellation/retry tests and Release interaction |
| 15 | Scalable native architecture | PASS for assessment — reviewed domain/actor/DI boundaries; no production-scale load certification |
| 16 | Meaningful CI-suitable tests | PASS — assertion review, 27 unit + 5 UI; adapter failure coverage limited below |
| 17 | GitHub-ready repository | PASS for preparation — project, clean-export build, docs, hygiene and CI syntax; hosted CI/publication not performed |

The original **17/17 implementation** claim is supported at assessment scope. It does not certify every Duo mode, physical-device scenario or network failure.

## Actual environment

- macOS **27.0.1 (26A434)**; Xcode **27.1 (27A9275)** at `/Applications/Xcode.app/Contents/Developer`.
- Apple Swift **6.4**, `swiftlang-6.4.0.34.1`; iOS Simulator SDK **27.1 (24A94232)**; deployment target **18.0**.
- Fresh tests/manual Release checks: **iPhone 17 Pro / iOS 26.5 (23F77)**, UUID `37E92A54-2AE2-4935-A576-83DD38B8823E`.
- Earlier bundles were independently read: iPhone 16 / iOS **18.2 (22C150)** and iPhone 17 Pro / iOS **26.5**, each 25 unit + 5 UI passes. New audit tests ran on 26.5, not again on 18.2.

## Fresh build/test evidence

### Debug build and full tests — PASS

The first fresh run reproduced **25 unit + 5 UI** passes. After the targeted assertion improvements:

```sh
xcodebuild test -project MarketPulse.xcodeproj -scheme MarketPulse \
  -destination 'platform=iOS Simulator,id=37E92A54-2AE2-4935-A576-83DD38B8823E' \
  -derivedDataPath /tmp/MarketPulseAuditDerived \
  -resultBundlePath /tmp/MarketPulse-Audit-Final.xcresult \
  -collect-test-diagnostics never -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

**27 unit + 5 UI passed**, no failures/skips/runtime warnings; exit 0, `TEST SUCCEEDED`. Log: `/tmp/marketpulse-audit-final-tests.log`. The [machine-generated summary](Docs/Evidence/audit-test-summary.json) reports 32 test functions and 46 device invocations including parameterized cases. These are different counting conventions, not 46 distinct test functions.

### Clean-export Release build — PASS

There is no initial Git commit, so a literal clean clone is not yet possible. Files selected by `git ls-files --cached --others --exclude-standard` were copied to a fresh `/tmp/MarketPulseAuditCheckout`, excluding `.git` and ignored artifacts. No local generator, downloaded package, signing credential or copied build product was used. From that directory:

```sh
xcodebuild build -project MarketPulse.xcodeproj -scheme MarketPulse \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/MarketPulseAuditRelease CODE_SIGNING_ALLOWED=NO
```

Result: exit 0, **BUILD SUCCEEDED**; log `/tmp/marketpulse-audit-release.log`. The resulting app was installed and operated on iPhone 17 Pro. Built metadata confirms iOS 18 minimum, launch screen, all four iPad orientations, no full-screen opt-out and a single scene. Release executable strings contain neither `UITestEchoTransport` nor `--ui-testing`; source excludes the fixture with `#if DEBUG`.

No Swift compiler warning/error remains. Xcode emits an App Intents metadata warning because the app has no AppIntents dependency, and its installed SDK-record diagnostic `invalidDigitCount(94232)` during tests. Both are disclosed; neither caused failure.

### Production-server diagnostic — PASS

```sh
xcrun swiftc -swift-version 6 -strict-concurrency=complete -parse-as-library \
  -module-cache-path /tmp/MarketPulseAuditSwiftCache \
  Domain/Models/*.swift Domain/Protocols/*.swift Domain/Services/*.swift \
  Data/Catalog/*.swift Data/Networking/*.swift Data/Repositories/*.swift \
  Data/Simulation/*.swift Tools/VerifyEcho.swift -o /tmp/marketpulse-audit-verify-echo
/tmp/marketpulse-audit-verify-echo --extended
```

Fresh result: **75 validated echoes, 0 rejected, no reconnecting state, Stop verified, exit 0**. [Complete output](Docs/Evidence/audit-real-echo.txt) is retained. This compiles production Domain/Data sources, not the UI-test fake. It establishes service availability at execution time, not a future guarantee.

## Visual and App Resizability review

All **12 original screenshots** were opened: both themes, details, largest accessibility text, unavailable state and five Duo views. Reviewed layouts are consistent, readable and explicitly simulated. Evidence problems identified above were addressed without redesign.

Fresh normal Release captures:

- [Main watchlist](Docs/Screenshots/Audit/watchlist-release.png)
- [Active connected state](Docs/Screenshots/Audit/connected-release.png)
- [Stock details](Docs/Screenshots/Audit/details-release.png)
- [Full landscape, dark theme](Docs/Screenshots/Audit/landscape-dark-release.png)

Start visibly progressed Connecting → Connected; prices moved through real echoes. Netflix selection and the feed survived portrait → landscape → portrait. Stop showed Stopped and retained the quote/history. The largest Dynamic Type test passed actual button hittability and minimum-height assertions. This does not cover every text-size/locale combination or continuous spoken VoiceOver quality.

**Apple App Resizability analysis:** applied the skill exported from installed Xcode and its five detection categories. Launch-screen/orientation/full-screen preconditions pass in source and effective Release metadata. No global screen bounds, device-idiom layout branches, orientation layout hacks, cached/mirrored safe-area insets or unsafe full-screen content overlays were found. SwiftUI `WindowGroup` and scene-local `scenePhase` already provide lifecycle handling; UIKit SceneDelegate migration does not apply. System navigation owns asymmetric safe areas. No source modernization was justified. This is skill-guided source/configuration analysis, not a runtime-layout certification.

**Duo evidence boundary:** the retained [expanded image](Docs/Screenshots/duo-inner-expanded.png), outer/folded, partially-open and inner-portrait captures visibly support earlier normal-pose layouts, matching list/detail values and clearance from the asymmetric system region. This audit's fresh boot reported **Data Migration Failed**. Installation/launch completed, but Device Hub and the inner framebuffer remained black after selecting Open. Troubleshooting stopped there. No successful fresh Duo pose, fold transition, freeform resize or OS Split View is claimed. Earlier images were not fabricated or relabeled as fresh. Smooth transition timing and physical Duo behavior remain unverified.

## GitHub readiness

- README covers setup, minimum OS, echo contract, sorting, lifecycle, test injection and build/test commands. Architecture/validation now separate fresh audit evidence from historical results.
- Project/shared scheme build directly. Plists, privacy manifest, JSON assets/string catalog and scheme XML parse successfully. There is no undocumented runtime dependency or project-generation step.
- Candidate publication files were scanned for private-key headers, common service tokens, assigned secrets, emails and personal home paths: **no findings**. Screenshots contain no personal contacts or assessment email. This bounded scan cannot guarantee future additions.
- No build products/result bundles/logs/signing material appear in the candidate list. `.gitignore` passed representative build, DerivedData, SwiftPM build, xcresult, user settings, `.env`, p12 and provisioning-profile checks. Small summaries and PNGs are intentional review artifacts.
- `NOTICES.md` states platform/service attribution and the absence of an owner-selected open-source license. No license was silently imposed; publication and general reuse rights are separate decisions.
- Workflow YAML, embedded Bash and Python syntax pass. `macos-15` and preferred `Xcode_26.3.app` are in the [official hosted-image inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md) checked during this audit. The workflow dynamically selects an installed iPhone runtime ≥18, without secrets or SDK downloads. **Hosted CI and Xcode 26.3 compilation remain unverified until an actual GitHub Actions run succeeds.**
- Local Git is `main`, with no commit and no remote. Ready for review and initial commit; publish only standalone `MarketPulse` when authorized. Nothing was pushed or published.

## Remaining verification limits

1. **Production URLSession failure boundaries:** repository fakes do not directly test real upgrade timeout/cancellation, late delegate events or remote closure during suspended socket I/O. A controlled local WebSocket peer is a useful follow-up. No corresponding production defect was reproduced.
2. **Adaptive/device:** fresh Duo poses, freeform resize, OS Split View, smooth fold performance, physical-device signing/execution and continuous VoiceOver narration remain unverified. Retained screenshots cannot prove these interactions.
3. **CI/toolchain:** no remote workflow ran. The clean-export build used Xcode 27.1; hosted Xcode 26.3 compatibility is based on API/configuration inspection until CI executes.
4. **Optional work:** Arabic translation and persistence remain out of scope; neither is a failing original mandatory requirement.

## Completed checklist

- [x] Trace mutation, handshake, cancellation, replay/session guards, Decimal and shared state.
- [x] Review assertions and improve significant uncovered behavior only.
- [x] Inspect all 12 original screenshots and apply available Apple source analysis.
- [x] Fresh clean-export Release build and complete automated test suite.
- [x] Verify 75 new real echoes and normal Release interaction.
- [x] Capture fresh iPhone evidence; record unsuccessful fresh Duo attempt honestly.
- [x] Check privacy, artifacts, license status, CI syntax and setup reproducibility.
- [x] Preserve production features and unrelated Flutter files; do not publish.

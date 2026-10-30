# MarketPulse Implementation Plan

## Authorized publication — 2026-10-30

- [x] Inspect standalone Git root, source/resources, relative documentation links and exclusions; scan candidate files for secrets, personal paths and unwanted artifacts.
- [x] Re-read audit result bundles and authenticate the requested GitHub account.
- [x] Verify the current complete suite and Release build: 27 unit + 5 UI PASS after simulator reboot; Release PASS. Explicit portrait-geometry waits isolate UI tests without removing assertions. Initial missed-tap failures and limits are recorded in VALIDATION.
- [ ] Create the requested initial commit on `main`, then publish only this directory to the authorized public repository.
- [ ] Inspect the real GitHub Actions run, fix any failures and verify public source/documentation/screenshots.

Expected changes: the UI test launch/rotation synchronization, publication documentation/evidence, and CI configuration only if hosted execution exposes a compatibility problem. No product redesign or new features. Historical checkpoints below describe their own dates.

## Follow-up — centered feed controls

- [x] Center the Start/Retry/Stop title independently of its symbol, preserving native button behavior and accessibility.
- [x] Existing UI suite: 5/5 PASS; Release build PASS. Fresh normal light/dark and test Retry/largest Dynamic Type captures inspected.
- [x] Inspect localization: English source only; empty string catalog, no Arabic translation, locale-aware numerical formatting.

Expected implementation files: `Features/Watchlist/Components/FeedControls.swift`, `Shared/DesignSystem/MarketTheme.swift`, and an adaptive `OnAccent` color asset. Evidence/validation notes will record this follow-up separately from the earlier audit snapshot.

**Goal:** A native, independently openable iOS assessment application whose simulated quotes change only after validated real WebSocket echoes.

**Architecture:** Foundation-only domain value types, an actor repository owning quotes and lifecycle, an injectable transport and simulation policy, and a MainActor Observation presentation store. SwiftUI list and detail share that store and repository. No third-party runtime dependencies.

**Stack:** Swift 6, SwiftUI, URLSessionWebSocketTask, Observation, Swift Charts, Swift Testing, XCTest UI automation. Minimum iOS 18.0. Built using installed Xcode 27.1 / iOS 27.1 SDK.

**Specification:** User-supplied MarketPulse assessment requirements (2026-10-29). All 17 original assessment requirements are mandatory. Later authorized publication is tracked above. Confidential assessment materials are not included.

## Scope and decisions

- Existing Flutter project is unrelated and has two pre-existing documentation changes. Preserve it completely. All new files reside in `MarketPulse/`, ready to publish as a standalone repository root.
- User explicitly requested autonomous implementation and opted out of routine design questions. Execute inline; keep a persistent checklist and perform a fresh final technical review.
- UI: neutral navy/teal native finance dashboard, adaptive NavigationSplitView, explicit simulated data disclosures. Native styling supersedes the parent repository's Flutter-only conventions for this separate Swift project.
- Financial change is relative to deterministic fictional seed prices, not a market day's opening price. History contains at most 120 validated received quotes per symbol.
- Stop and background invalidate the active run before closing transport. Background preserves user intent; foreground resumes only if desired. Retry delays are exponential, capped and jittered, with a finite retry budget and manual retry.

## Expected files (all new)

- `MarketPulse.xcodeproj/project.pbxproj` and shared scheme: application, unit and UI targets.
- `App/MarketPulseApp.swift`, `App/AppContainer.swift`: composition and scene lifecycle.
- `Domain/Models/{Price,Stock,FeedState}.swift`, `Domain/Services/StockSort.swift`, `Domain/Protocols/{WebSocketTransport,MarketRepository,FeedTiming}.swift`: domain contracts.
- `Data/Catalog/StockCatalog.swift`, `Data/Simulation/PriceGenerator.swift`: 25 stocks and deterministic-testable generation.
- `Data/Networking/{PriceMessage,URLSessionWebSocketTransport}.swift`, `Data/Repositories/LiveMarketRepository.swift`: validated echo-only updates and robust lifecycle.
- `Features/Watchlist/Models/MarketStore.swift`, watchlist/detail views and components, shared theme/formatting/resources.
- `MarketPulseTests/`: catalog, arithmetic, sorting, generation, message, repository, presentation tests and fakes.
- `MarketPulseUITests/`: deterministic launch, sorting, navigation, control, consistency and adaptive coverage. Real-service smoke coverage is in the separate opt-in `Tools/VerifyEcho.swift` diagnostic.
- `.github/workflows/ios-ci.yml`, `.gitignore`, `README.md`, `ARCHITECTURE.md`, `VALIDATION.md`, `Docs/Screenshots/`.

## Execution checklist

- [x] Inspect current workspace, Git status, macOS, Xcode, Swift, SDKs, simulators.
- [x] 1. Create Xcode project/shared scheme; prove initial simulator build.
- [x] 2. Write and run domain tests; implement catalog, Decimal calculations, sorting and simulation; rerun.
- [x] 3. Write integration tests with controllable transport/time; implement handshake, message validation, echo-only repository, start/stop, retries and background policy; rerun.
- [x] 4. Implement shared observable state, watchlist, details, sorting and feed controls; build/run.
- [x] 5. Polish native light/dark UI, accessibility, Dynamic Type and bounded chart.
- [x] 6. Test available iPhone, minimum-version simulator and actual iPhone Duo poses/adaptive layouts. Freeform resize visual verification remains an explicitly documented simulator limitation.
- [x] 7. Run all unit/UI tests, real Postman smoke, concurrency/cancellation review and fix defects.
- [x] 8. Capture real screenshots, finish docs/CI, perform independent review and verify deliverable hygiene.

## Review focus / required regressions

- Candidate send before echo must leave the public quote untouched (integration test).
- Manual Stop during handshake/retry/receive must invalidate all late work (controlled async tests).
- Repeated Start and old connection callbacks must never create duplicate active loops (factory counts/session tests).
- Invalid, duplicate, unsolicited, stale, oversized or out-of-order payloads must not mutate state (codec/validator tests).
- Selection and shared prices must survive navigation and width changes (presentation/UI tests and actual Duo poses).

## Evidence ledger

- Initial inspection: macOS 27.0.1 (26A434), Xcode 27.1 (27A9275), Swift 6.4; iOS SDK 27.1. Existing iPhone Duo simulator on iOS 27.1 available. No SDK downloads needed.
- Simulator tools require access outside the workspace sandbox; the authorized inspection succeeded using approved tool escalation. XcodeBuildMCP tools are not exposed; use Xcode command line and native UI automation.
- No existing MarketPulse code found. No existing Flutter source modified.

- Phase 1: initial simulator build PASS on iPhone 17 Pro / iOS 26.5.
- Phase 2: eight domain test functions (including 15 parameterized price cases) PASS. Red compile before implementation and green simulator run recorded under `/tmp/marketpulse-domain-*.log`.
- Phase 3: transport/repository and first message/lifecycle regressions implemented; compilation caught an ISO8601 parse/format overload mismatch, corrected to explicit Foundation format-style construction. Verification in progress.

- Phase 3: 16 domain/message/repository test functions PASS. Production real-network diagnostic PASS: handshake, 3 validated echoes, Stop.
- Phase 4: app runs on iPhone17Pro/iOS26.5; UI launch/sort/details/failure tests passed. Start/Stop/shared-price UI test passed on isolated rerun.
- Environment finding: this Mac has 8GiB RAM. Running Duo27.1 alongside UI tests caused heavy simulator process load and missed synthesized inputs. Run devices sequentially. First Duo migration/launch attempt was unsuccessful; no screenshot claims.
- Phase 7: expanded23-unit/5-UI suite running, final independent read-only review dispatched via requesting-code-review skill.

- Independent review completed. Echo-only ingestion, Decimal calculations, isolation and shared quote identity confirmed. Two lifecycle findings promoted to required correctness fixes: multiple generated scenes could fight over global lifecycle; suspended send could retain the repository and block its timeout. Implemented explicit single-scene configuration, synchronous message preparation with I/O outside repository ownership, independent watchdog, and explicit teardown close.
- Lifetime regression tests observed RED: suspended send and suspended receive were not closed on repository release, and a stalled send had no independent deadline. Three assertions across two test functions now cover the fix; full green run pending.
- Largest Dynamic Type UI regression exposed split button words and controls below the long explanation. Moved controls before help, stacked buttons at accessibility sizes, shortened the panel heading, and made the watchlist section header adaptive. Existing failure test rerunning.

## Final checkpoint — completed 2026-10-29

- All 25 unit tests and all 5 UI tests PASS on iPhone 17 Pro / iOS 26.5 and iPhone 16 / iOS 18.2. Final affected-unit rerun PASS after the last transport correction. Debug and Release builds PASS with strict Swift 6 concurrency.
- Actual normal app real WebSocket verified. Final extended diagnostic received 75 valid Postman echoes with zero rejections and no reconnect, then successfully stopped. A short resource lifetime found during visual inspection was removed; handshake and echo deadlines remain bounded.
- Effective built Info.plist confirms one scene. Independent review findings about suspended I/O ownership and timeout were fixed and regression-tested RED → GREEN.
- Corrected truncated signed percentage text and verified through real screenshots and iOS 18 UI tests.
- Actual Duo Closed, Open and Partially Open poses, folding back to selected details, and inner-display rotation verified with live prices. Initial migration/renderer delays resolved after a sequential launch. No SDK downloaded and no simulator erased.
- Freeform resize mode remains visually unverified because Device Hub displayed a black surface. This limitation is in README and VALIDATION; no fabricated screenshot or success claim.
- Twelve real simulator screenshots, documentation, workflow, privacy/resources and shared Xcode scheme prepared. Own local Git repository initialized on main with no remote or commit. No source published and parent Flutter files preserved.
- Remaining optional/external checks: hosted CI, physical-device/VoiceOver narration, freeform resizing/Split View, Arabic localization. See VALIDATION for exact commands and evidence.

## Independent final audit — completed 2026-10-29

- [x] Reinspect implementation and meaningful assertions, with a fresh read-only reviewer. No confirmed P0/P1 functional defect; production code/resources/project configuration preserved.
- [x] Strengthen a vacuous late-handshake test; add restart-before-old-open and receive-concurrency/exact-production regressions. Strengthen landscape geometry and price-hittability checks.
- [x] Fresh Debug/test validation: original 25 unit + 5 UI reproduced, then final 27 unit + 5 UI PASS on iOS 26.5. Earlier iOS 18 result bundle independently read.
- [x] Fresh Release build PASS from a clean source export with separate DerivedData; no generator, packages or signing credentials. All 45 build/test/diagnostic inputs still match that export.
- [x] Fresh production diagnostic PASS: 75 accepted Postman echoes, zero rejected, no reconnect, Stop verified. Normal Release Start/Stop, navigation, dark/light and portrait/landscape observed.
- [x] Inspect all 12 original images; capture four fresh Release images, refresh stale failure evidence, flag the cropped legacy landscape artifact.
- [x] Apply installed Apple App Resizability analysis. Fresh Duo boot/launch attempted once; migration failure and black inner surface prevented new visual certification. No extended black-screen troubleshooting, reset or download.
- [x] Check CI syntax/current runner inventory, artifact exclusions and sensitive-content patterns; document license status without assigning an unrequested license. No push, remote or commit created.
- [x] Complete AUDIT.md, update README/ARCHITECTURE/VALIDATION and preserve portable evidence. Remaining limits are stated explicitly in AUDIT.md.

# Validation record

## Publication verification — 2026-10-30

Fresh local verification of the publication source: **27 unit-test functions and 5 UI tests PASS; Release build PASS**, both commands exit 0. The [machine-generated summary](Docs/Evidence/publication-local-test-summary.json) reports 32 functions and 46 device invocations including parameterized cases. The environment remains Xcode 27.1, Swift 6.4, iPhone 17 Pro / iOS 26.5.

```sh
xcodebuild test -project MarketPulse.xcodeproj -scheme MarketPulse \
  -destination 'platform=iOS Simulator,id=37E92A54-2AE2-4935-A576-83DD38B8823E' \
  -derivedDataPath /tmp/MarketPulseControlDerived \
  -resultBundlePath /tmp/MarketPulse-Publication-Verified.xcresult \
  -collect-test-diagnostics never -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO

xcodebuild build -project MarketPulse.xcodeproj -scheme MarketPulse \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/MarketPulseControlRelease CODE_SIGNING_ALLOWED=NO
```

The initial two complete attempts had one large-text UI failure: the synthesized Start tap did not begin a connection. The isolated test passed, as did the rotation/large-text pair after rebooting the simulator. Explicit portrait-geometry waits now isolate UI tests and verify restoration after rotation; all existing assertions and timeouts remain. The full suite then passed on the rebooted simulator. A simulator/input timing issue was observed; orientation synchronization alone did not eliminate the earlier failure, and no product defect was established. Temporary diagnostic instrumentation was removed before this final run. Logs are `/tmp/marketpulse-publication-verified-tests.log` and `/tmp/marketpulse-publication-release.log`.

Pre-publication checks: source/resources/shared scheme complete; relative Markdown links valid; no secrets, personal home paths, private email addresses, signing material, assessment documents or unwanted build products in the candidate files. Git author identity uses the requested GitHub username and GitHub noreply address. The demonstration MP4 and actual simulator PNGs are intentional review artifacts. No reuse license was added.

Hosted CI is **pending** until the initial public push and actual workflow execution. The dated sections below are historical evidence, including their original unpublished/CI-unverified status.

## Control-alignment follow-up — 2026-10-29

Centered the Start/Retry/Stop titles independently of their icons using one local LabelStyle, and added an adaptive theme color so the primary button's icon/text are readable in light and dark mode. Native button actions, state, identifiers, minimum height and accessibility-size stacking are unchanged. Scope: `FeedControls.swift`, `MarketTheme.swift`, and `OnAccent.colorset/Contents.json`; no networking/domain changes.

**PASS:** all five existing UI tests, including failure/Retry and largest Dynamic Type; normal Release build; actual light/dark screenshots inspected. The earlier 27-unit-test result remains historical; unit tests were not rerun for this rendering-only change.

```sh
xcodebuild test -project MarketPulse.xcodeproj -scheme MarketPulse \
  -destination 'platform=iOS Simulator,id=37E92A54-2AE2-4935-A576-83DD38B8823E' \
  -derivedDataPath /tmp/MarketPulseControlDerived \
  -resultBundlePath /tmp/MarketPulse-ControlAlignment.xcresult \
  -only-testing:MarketPulseUITests -collect-test-diagnostics never \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO

xcodebuild build -project MarketPulse.xcodeproj -scheme MarketPulse \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/MarketPulseControlRelease CODE_SIGNING_ALLOWED=NO
```

Both commands exited 0. Logs: `/tmp/marketpulse-control-tests.log`, `/tmp/marketpulse-control-release.log`. Actual captures: [light](Docs/Screenshots/Controls/watchlist-light.png), [dark](Docs/Screenshots/Controls/watchlist-dark.png), [largest text](Docs/Screenshots/Controls/largest-type-uitest.png), [Retry](Docs/Screenshots/Controls/retry-uitest.png). Release was installed normally without test launch arguments; the simulator appearance was restored to light.

Localization inspection: source language `en`, zero string-catalog entries, no translated locales. The interface is English only; locale-aware money/percent formatting is implemented. No Arabic translation was added by this follow-up.

Actual local validation on **2026-10-29**. Network-independent tests and real-service checks are identified separately. Nothing has been published; remote CI has not run.

## Final audit addendum

The later independent audit is recorded in [AUDIT.md](AUDIT.md), including exact fresh commands and evidence. It reproduced the original 25 unit + 5 UI passes, strengthened significant handshake/duplicate-loop/landscape assertions, then passed **27 unit + 5 UI tests** on iPhone 17 Pro / iOS 26.5. A **fresh-source-export Release build passed**, as did a new **75 real Postman echoes / zero rejections / no reconnect / successful Stop** diagnostic. Production code and Xcode configuration were unchanged.

Fresh result: `/tmp/MarketPulse-Audit-Final.xcresult`; build log: `/tmp/marketpulse-audit-release.log`. Small portable summaries are in [Docs/Evidence](Docs/Evidence/README.md), and four new actual normal Release screenshots are indexed in [Docs/Screenshots](Docs/Screenshots/README.md).

The audit inspected all 12 earlier screenshots. Its new Duo boot reported a migration failure and a black expanded display; it did **not** repeat the earlier successful pose checks below. Freeform resizing and OS Split View remain visually unverified. The old cropped landscape test attachment is not full visual evidence; the fresh normal Release landscape screenshot supersedes it. Earlier iOS 18 results were read from their actual result bundle; the newly added tests were not rerun on 18.2. Hosted CI and direct automated URLSession failure injection remain unverified.

The following sections retain the original implementation validation history; the addendum and audit take precedence for current counts and evidence limits.

## Environment

| Item | Installed value |
|---|---|
| macOS | 27.0.1 (26A434) |
| Xcode | 27.1 (27A9275), `/Applications/Xcode.app/Contents/Developer` |
| Swift | Apple Swift 6.4 (`swiftlang-6.4.0.34.1`) |
| iOS / simulator SDK | 27.1 (24A94232) |
| Deployment target | iOS 18.0 |
| Machine memory | 8 GiB |
| Installed runtimes | iOS 17.0.1, 17.2, 18.2, 26.1, 26.5, 27.0, 27.1 |
| Primary device | iPhone 17 Pro, iOS 26.5 (23F77), `37E92A54-2AE2-4935-A576-83DD38B8823E` |
| Minimum-family device | iPhone 16, iOS 18.2, `644AFDDF-A55A-4921-9CA9-C3DAB915D79A` |
| Duo installed | iPhone Duo, iOS 27.1 (24A94425), `1F092F53-F2AC-4D34-84E9-ACC2F5AC006C` |

Inspection used `pwd`, `git status --short`, `sw_vers`, `xcode-select -p`, `xcodebuild -version`, `xcodebuild -showsdks`, `swift --version`, `xcrun simctl list devices available`, `xcrun simctl list runtimes` and `xcrun simctl list devicetypes`. No SDK or runtime was downloaded. The unrelated parent Flutter app and its pre-existing documentation changes were preserved.

## Builds and tests

Commands run from the MarketPulse directory. Result bundles and build products stay outside the deliverable.

**Project inspection and Debug build: PASS**

```sh
xcodebuild -list -project MarketPulse.xcodeproj
xcodebuild build -project MarketPulse.xcodeproj -scheme MarketPulse -destination 'platform=iOS Simulator,id=37E92A54-2AE2-4935-A576-83DD38B8823E' -derivedDataPath /tmp/MarketPulseDerived CODE_SIGNING_ALLOWED=NO
```

**iPhone 17 Pro / iOS 26.5: PASS — 25 unit tests, 5 UI tests, zero failures.**

```sh
xcodebuild test -project MarketPulse.xcodeproj -scheme MarketPulse -destination 'platform=iOS Simulator,id=37E92A54-2AE2-4935-A576-83DD38B8823E' -derivedDataPath /tmp/MarketPulseDerived -resultBundlePath /tmp/MarketPulse-Final-iPhone.xcresult -collect-test-diagnostics never -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

**iPhone 16 / iOS 18.2: PASS — 25 unit tests, 5 UI tests, zero failures.** This includes the final single-scene configuration and corrected movement labels.

```sh
xcodebuild test -project MarketPulse.xcodeproj -scheme MarketPulse -destination 'platform=iOS Simulator,id=644AFDDF-A55A-4921-9CA9-C3DAB915D79A' -derivedDataPath /tmp/MarketPulseDerived -resultBundlePath /tmp/MarketPulse-iOS18.xcresult -collect-test-diagnostics never -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

**Final affected-unit rerun: PASS — 25 tests, zero failures.** Rebuilt after the final transport resource-lifetime correction.

```sh
xcodebuild test -project MarketPulse.xcodeproj -scheme MarketPulse -destination 'platform=iOS Simulator,id=644AFDDF-A55A-4921-9CA9-C3DAB915D79A' -derivedDataPath /tmp/MarketPulseDerived -resultBundlePath /tmp/MarketPulse-Final-Unit.xcresult -only-testing:MarketPulseTests -collect-test-diagnostics never -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

**Final Release build: PASS**

```sh
xcodebuild build -project MarketPulse.xcodeproj -scheme MarketPulse -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/MarketPulseRelease CODE_SIGNING_ALLOWED=NO
```

Swift 6, complete strict concurrency and warnings-as-errors are enabled. No Swift compiler warnings or errors remain. Xcode prints an informational App Intents metadata warning because this app does not depend on AppIntents. Its SDK-record diagnostic prints `invalidDigitCount(94232)` with the installed SDK; builds and tests still succeed. Neither message was hidden.

Local logs: `/tmp/marketpulse-final-build.log`, `/tmp/marketpulse-final-iphone.log`, `/tmp/marketpulse-ios18-tests.log`, `/tmp/marketpulse-final-unit.log`, `/tmp/marketpulse-final-release.log`. Parameterized cases are additional invocations within the 25 reported Swift Testing functions.

## Coverage

| Area | Verified behavior |
|---|---|
| Catalog | Exactly 25 required unique symbols, positive seeds, nonempty descriptions |
| Financial values | Positive/negative/zero movement, reference percentage, Decimal cent rounding, invalid/extreme rejection |
| Sorting | Both metrics and directions, ticker tie-breaks, changed received values |
| Generator | Valid bounded movement, seeded randomness, round-robin fairness |
| Messages | Codable, registration, size limit, malformed JSON, schema/type, symbol, price, pending match, duplicates, ordering, age and session |
| Repository | Handshake gating, send without publication, delivered echo publication, single connection, Stop during connection, late echoes, retries, finite budget, background/foreground intent |
| Lifetime | Release closes suspended send/receive; independent watchdog closes hung send; Stop cancels retry |
| Presentation | Identical shared quote object/value, no extra detail connection, locale formatting, semantic direction |
| UI | Launch, count, sorting, navigation, shared prices, Start/Stop, failure, landscape selection, largest Dynamic Type |

UI tests inject the Debug-only fake echo transport. They do not prove public-service availability. Normal launches and Release use the real URLSession transport.

## Real-network evidence

**PASS**, final production sources, actual TLS WebSocket, no fake:

```sh
xcrun swiftc -swift-version 6 -strict-concurrency=complete -parse-as-library -module-cache-path /tmp/MarketPulseSwiftCache Domain/Models/*.swift Domain/Protocols/*.swift Domain/Services/*.swift Data/Catalog/*.swift Data/Networking/*.swift Data/Repositories/*.swift Data/Simulation/*.swift Tools/VerifyEcho.swift -o /tmp/marketpulse-verify-echo
/tmp/marketpulse-verify-echo --extended
```

Actual output in `/tmp/marketpulse-extended-real-echo.log`:

```text
state=connecting, validatedEchoes=0, rejected=0
state=connected, validatedEchoes=0, rejected=0
... 75 validated echoed messages, no reconnecting state ...
state=connected, validatedEchoes=75, rejected=0
PASS: production handshake, 75 validated server echoes, and Stop verified.
```

The normal simulator app was operated through Device Hub: Start → Connecting → Connected, visible movement, matching Netflix details, recovery during an earlier interrupted session, and Stop retaining the accepted price/history. Real light/dark screenshots are in [Docs/Screenshots](Docs/Screenshots/README.md).

Apple's [resource timeout documentation](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/timeoutintervalforresource) describes a limit on the entire task. The initially short resource lifetime was removed for this long-lived feed. Independent handshake and echo deadlines remain. The final 75-echo run confirms operation beyond one minute without reconnecting at test time.

## Adaptive device coverage

- iPhone 17 Pro / iOS 26.5: portrait, landscape, navigation, light/dark, largest accessibility text, real feed controls verified.
- iPhone 16 / iOS 18.2: full unit/UI suite, compact navigation, landscape selection and largest text controls verified.
- iPhone Duo / iOS 27.1: actual Device Hub Closed, Open and Partially Open poses verified. Outer display shows compact navigation; inner landscape shows two synchronized columns. Folding back preserves selected Netflix details and active feed. Rotating the inner display to portrait preserves selection with system sidebar access. Real screenshots are saved.
- Freeform Device Hub resize mode: **NOT VERIFIED visually**. Width changes were attempted at 375 and 900 points. Accessibility continued exposing selected Netflix, connected state and both columns at the wider proposal, but the resizable framebuffer remained black. This does not establish successful visual resizing. OS Split View with another app was not exercised. Normal Duo pose captures above are independently verified.
- Physical-device behavior and continuous VoiceOver narration were not tested. Accessibility labels, values and reachable controls were inspected through automation.

## Review and fixes

A fresh independent review covered echo gating, Decimal, actor isolation, ownership, retries and navigation. Resolved findings:

1. Explicit single-scene configuration prevents competing scene lifecycle signals. Built Info.plist was inspected: `UIApplicationSupportsMultipleScenes` is false.
2. Producer I/O no longer retains the repository across suspended send. Independent watchdog and deinit close unblock I/O. Regressions failed before the fix and pass afterward.
3. Largest Dynamic Type originally pushed controls below help and wrapped button words. Controls now precede help and stack at accessibility sizes. Both device suites pass.
4. Signed percentage labels initially truncated. Intrinsic-width text now displays complete values; actual screenshots and iOS 18 tests verify the change.
5. A healthy socket no longer has a 60-second whole-resource timeout. Extended real-server validation passed after correction.

Simultaneous Duo boot and UI testing initially overloaded the 8 GiB machine and caused missed inputs plus a stalled diagnostic collector. The affected test passed in isolation. Subsequent runs use one simulator with expensive system diagnostic collection disabled; normal screenshots/results remain available. No unrelated process, user data or simulator was erased.

The existing Duo reported a data migration failure on boot and initially rendered slowly. A sequential retry eventually rendered successfully; all claimed poses were observed afterward. This machine showed substantial simulator/system process load and delayed pose transitions. Smooth fold animation or frame-rate performance is therefore **not certified** by these screenshots. No simulator reset or runtime installation was needed.

## Original assessment acceptance

| # | Requirement | Result |
|---|---|---|
| 1 | At least 25 scrollable symbols | PASS |
| 2 | Company, ticker, price, movement | PASS |
| 3 | Actual required Postman WebSocket | PASS |
| 4 | Random client-generated simulated updates | PASS |
| 5 | Send generated candidates through WebSocket | PASS |
| 6 | Receive server echoes | PASS |
| 7 | Publish only validated received echoes | PASS |
| 8 | Sort by price | PASS |
| 9 | Sort by price change | PASS |
| 10 | Select stock and open details | PASS |
| 11 | Price, movement and description in details | PASS |
| 12 | Shared real-time list/detail state | PASS |
| 13 | Visible accurate connection status | PASS |
| 14 | Start/Stop connection controls | PASS |
| 15 | Scalable native architecture | PASS — reviewed actor/DI boundaries |
| 16 | Meaningful CI-suitable automated tests | PASS — 25 unit + 5 UI tests |
| 17 | Complete GitHub-ready repository | PASS — project, resources, docs and CI prepared locally |

## CI and limitations

The workflow selects an installed stable Xcode and supported simulator on `macos-15`, builds and runs unit/UI tests without secrets. **Remote CI not executed.** No GitHub repository or submission email was created.

No known P0/P1 functional defect remains in the verified flows. Remaining validation limitations: freeform resize/Split View is unverified, the overloaded Duo simulator cannot establish smooth frame timing, physical-device/VoiceOver narration testing is outstanding, and hosted CI has not executed. Optional Arabic localization is P2. These limitations are explicit; no claim of a physical-device release or production trading readiness is made.

## Repository hygiene

The dedicated MarketPulse directory has its own local Git repository on `main`, no remote, no commits and no published content. Source is ready for review and an initial commit. The shared Xcode project opens directly. JSON assets, Info.plist, privacy manifest and shared scheme were parsed successfully; no forced parsing unwraps, detached tasks, embedded keys or credentials were found in the source review. Builds, logs and result bundles are outside the repository. The parent Flutter changes remain untouched.

Handoff: the final Release app was installed and launched successfully on iPhone 17 Pro / iOS 26.5. Device Hub visibly showed the 25-symbol watchlist, Stopped status and enabled Start. Duo was shut down after testing. The workflow YAML and local documentation links were checked; all 12 screenshot files exist.

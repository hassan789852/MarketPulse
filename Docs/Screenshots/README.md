# Actual simulator captures

All PNGs are captured from the running app or XCTest attachments. No mockups or generated screenshots are used. All quoted prices are fictional.

## Latest control-alignment update

The Start/Retry/Stop words are centered independently of their symbols. These captures supersede earlier images for button alignment:

- [Light watchlist](Controls/watchlist-light.png) and [dark watchlist](Controls/watchlist-dark.png): normal Release launch, stopped reference prices.
- [Largest Dynamic Type](Controls/largest-type-uitest.png): actual UI-test capture, accessible stacked controls.
- [Retry](Controls/retry-uitest.png): actual UI-test capture, deliberately injected connection failure.

All four were inspected on iPhone 17 Pro / iOS 26.5. Earlier screenshots below remain historical evidence of the prior audit revision.

## Final audit captures — normal Release app

Fresh captures on iPhone 17 Pro / iOS 26.5, 2026-10-29, installed from the clean-export Release build. No test launch arguments or fake transport:

- [Main watchlist](Audit/watchlist-release.png): initial stopped state, all 25 symbols in the data set.
- [Active connected feed](Audit/connected-release.png): actual Postman connection and received price movements.
- [Stock details](Audit/details-release.png): Netflix, received quote/history and connected status.
- [Landscape, dark theme](Audit/landscape-dark-release.png): full actual landscape framebuffer, selected Netflix preserved after rotation. This supersedes the cropped legacy XCTest landscape attachment below as visual evidence.

The audit inspected all 12 pre-existing screenshots. The earlier Duo expanded capture remains available below. A fresh Duo run reported a migration error and rendered black, so no new successful Duo screenshot is claimed. Freeform resize and OS Split View remain unverified.

## Normal app, real WebSocket

iPhone 17 Pro, iOS 26.5:

- [Light watchlist](iphone-watchlist-light.png): connected, prices from validated Postman echoes.
- [Dark watchlist](iphone-watchlist-dark.png): the same live feed and theme adaptation.
- [Dark details](iphone-details-dark.png): Netflix and received history.
- [Light details](iphone-details-light.png): Stop retains the last accepted price and chart.

iPhone Duo, iOS 27.1, operated through Xcode Device Hub:

- [Outer watchlist](duo-outer-watchlist.png): compact navigation and safe areas.
- [Inner expanded layout](duo-inner-expanded.png): real received Netflix price matches in both columns.
- [Outer details after folding](duo-outer-details-after-fold.png): selection and connected feed retained.
- [Partially open](duo-partially-open.png): both columns and shared live quote preserved.
- [Inner portrait](duo-inner-portrait.png): selected details remain visible; system sidebar access adapts to available width.

These are framebuffer captures of the actual selected poses. They do not draw a simulated device shell or fabricate a fold angle.

## Network-independent UI tests

These screenshots use the explicitly injected Debug-only fake echo transport, not the public service:

- [Largest accessibility text size](iphone-accessibility-largest.png): controls remain reachable and words do not clip.
- [Legacy landscape attachment](iphone-landscape-uitest.png): retained for traceability; it is cropped and partly black and must not be treated as complete visual landscape evidence. The strengthened test separately verifies landscape geometry, selected ticker/company and price hittability; use the fresh normal Release capture above for visual review.
- [Unavailable connection](iphone-unavailable-uitest.png): refreshed from the final audit test bundle. Honest failure, seeded prices retained and complete percentage labels.

Device and pose coverage is recorded in [VALIDATION.md](../../VALIDATION.md).

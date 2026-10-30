# MarketPulse architecture

MarketPulse is a native, read-only demonstration of an echo-driven price feed. Its architecture keeps financial rules independent of rendering, makes concurrency ownership explicit, and permits deterministic testing without a network connection.

## Layers and ownership

| Area | Responsibility | Isolation |
|---|---|---|
| Domain | Validated Decimal prices, stocks, quotes, sort order and service contracts | Immutable Sendable values |
| Catalog / simulation | Fictional seeds, curated descriptions, fair bounded price candidates | Repository-owned generator value |
| URLSession transport | TLS WebSocket, handshake detection, framing, close and timeouts | One actor per connection attempt |
| LiveMarketRepository | Authoritative quotes, echo validation, lifecycle, retry budget, bounded history | One actor for the application |
| MarketStore / QuoteModel | Observable projection and navigation/sort state | MainActor |
| SwiftUI features | Rendering, accessibility and explicit user actions | MainActor |
| AppContainer | Production/test dependency composition | MainActor |

A `QuoteModel` has stable ticker identity. The watchlist and detail screen reference the **same object**. Opening details constructs neither a repository nor a transport. Snapshot projection updates only the changed row models; a price change causes the deterministic sort order to be recomputed for 25 items. Unchanged rows keep their identities and observable values.

## Data flow

```mermaid
sequenceDiagram
    actor User
    participant UI as SwiftUI / MarketStore
    participant Repo as Repository actor
    participant WS as URLSession transport actor
    participant Echo as Postman echo server
    User->>UI: Start
    UI->>Repo: start()
    Repo->>WS: connect()
    WS->>Echo: TLS + WebSocket upgrade
    Echo-->>WS: Handshake accepted
    WS-->>Repo: connect returns from delegate confirmation
    Repo-->>UI: Connected
    loop Once each second
        Repo->>Repo: Generate candidate, register expected message
        Repo->>WS: send(JSON)
        WS->>Echo: Candidate frame
        Note over Repo,UI: Visible quote has NOT changed
        Echo-->>WS: Echoed frame
        WS-->>Repo: receive()
        Repo->>Repo: Decode, validate, apply, append bounded history
        Repo-->>UI: Snapshot
        UI->>UI: Update shared row/detail quote
    end
    User->>UI: Stop
    UI->>Repo: stop()
    Repo->>Repo: Invalidate session before any await
    Repo-->>UI: Stopped; retain last validated values
    Repo->>WS: close()
```

## Money and message integrity

`Price` is a validated Decimal value: USD 0.01 through 1,000,000.00. Computed values use bankers' rounding to two places. Wire input must be an ASCII decimal string with at most two fraction digits; signs, grouping, exponent notation, NaN, trailing garbage and zero are rejected. `Double` is used only when projecting validated amounts into chart coordinates, never for a price calculation.

Absolute change is `current − reference`; percentage is `(current − reference) / reference`. References are fictional deterministic constants. Sorting by change uses the signed percentage, with ascending ticker tie-breaking in both directions. The round-robin generator visits every symbol once per 25 updates and draws a movement within ±80 basis points, rounded to cents and clamped to the valid price range.

A frame includes schema version, message type, session UUID, message UUID, monotonically increasing sequence, symbol, decimal price string and UTC timestamp. Validation checks the 4 KiB limit, exact contract, known ticker, price validity, active session, outstanding message identity, exact sent payload, age, and increasing sequence. An unsolicited but otherwise valid message cannot update a quote. Duplicate or old messages cannot pass the sequence check. Outstanding entries through an accepted sequence are retired, keeping memory bounded.

## Concurrency, task ownership and lifecycle

A repository has one connection task, receive task, production task, retry task and independent echo-watchdog task. Tasks capture the repository weakly and perform short actor-isolated operations; transport I/O and clock suspension occur away from presentation. Candidate preparation is synchronous on the repository actor; the production task then sends without retaining that actor. An independent watchdog can expire a pending echo even if send never returns. Repository teardown explicitly closes the active transport, releasing suspended send and receive operations. There are no detached tasks, timers, Combine subscriptions or unsafe shared mutable application state.

`URLSessionWebSocketDelegate.didOpenWithProtocol` is the handshake gate. A 12-second timeout bounds opening. The transport uses an ephemeral session, a serial delegate queue and an async event stream. Socket frames are size-limited at the URLSession task and codec boundaries. Closing resumes a suspended handshake and cancels the socket, delegate stream and timeout.

Every Stop or background transition clears the session guard synchronously before awaiting transport cleanup. Every callback verifies its captured session. Thus, a late send completion, echo, open callback or retry cannot resurrect a stopped feed or mutate a replacement session.

After an unexpected failure, the old attempt closes before retry. Delays use exponential backoff (1, 2, 4, 8, 16 seconds) with 75–125% jitter, capped at 20 seconds. Five retries are allowed after the initial attempt. A validated echo, not merely a handshake, resets the failure budget. A silent socket is detected by the 15-second outstanding echo timeout and pending-message bound. After exhaustion, the UI displays Disconnected and allows manual Retry.

The app explicitly declares a single scene (`UIApplicationSupportsMultipleScenes = false`): one shared tracking session and one navigation selection, with adaptive columns rather than independent windows. Backgrounding pauses network activity while preserving desired-running intent. Returning to the foreground reconnects only if that intent remains true. Transient `inactive` events do not flap the feed. Manual Stop clears intent. Last valid quotes and history remain visible; process termination intentionally resets the demonstration to seed values.

## Dependency injection and tests

`WebSocketTransport`, `PriceGenerating`, `FeedClock` and `RandomSource` make I/O, time and randomness independently controllable. The repository factory creates a fresh transport for each attempt. Unit tests use manually delivered echoes and explicit handshakes, not an auto-updating fake repository. A cancellation-aware manual clock advances retries and timeout scenarios without waiting real seconds.

Presentation tests assert shared object identity and cross-screen values. XCTest UI tests explicitly launch Debug builds with `--ui-testing`; only that launch uses `UITestEchoTransport`. The Release binary excludes the fixture. Normal launches always use the real endpoint. `Tools/VerifyEcho.swift` is a separate opt-in diagnostic compiled against production Domain/Data sources; default CI never depends on Postman's availability.

The final audit added an adversarial handshake that can complete after close, a restart-before-old-open regression, and receive-concurrency/production-count assertions under repeated Start. These exercise the repository's own guards. URLSession adapter failures (upgrade timeout, cancellation during upgrade and remote closure during suspended I/O) still lack automated tests against a controlled local WebSocket peer. Repository fakes and the real-service success diagnostic do not establish that additional coverage.

## Adaptive UI and accessibility

NavigationSplitView adapts between a watchlist push flow and a two-column layout. Selection lives above the navigation columns. Layout derives from size class and the current container; it never reads device names, global screen bounds or orientation to select a layout. System containers own safe areas and bars, including Duo's asymmetric reserved region. Dynamic Type uses stacked rows for accessibility sizes, flexible panels and native scrolling. Text and arrows accompany positive/negative colors. Price animation respects Reduced Motion. UI identifiers are stable and independent of changing prices.

## Production extension points

A real feed would replace the echo-specific repository ingestion policy and transport endpoint, while reusing domain price rules and presentation. It would need authenticated subscriptions, exchange sequence/replay semantics, trading calendars, symbol metadata, corporate actions, transport heartbeats, authoritative timestamps, audit/observability policies and service-level rate limits. An echo acceptance ledger should not be reused as an exchange subscription protocol.

Regional support belongs in configuration and domain currency metadata, not device checks. Current formatting is locale-aware USD, and user-facing UI strings are prepared for string-catalog localization. Add translated descriptions and localized accessibility text, currency-specific precision and exchange sessions as required. No banking, orders, payments or account features are implied by this assessment.

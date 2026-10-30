import Foundation
import OSLog

actor LiveMarketRepository: MarketRepository {
    private let transportFactory: TransportFactory
    private let clock: any FeedClock
    private let policy: FeedPolicy
    private var generator: any PriceGenerating
    private var retryRandom: any RandomSource
    private var quotes: [StockQuote]
    private var state: FeedState = .stopped
    private var wantsRunning = false
    private var foreground = true
    private var sessionID: UUID?
    private var retryID: UUID?
    private var sequence: UInt64 = 0
    private var failures = 0
    private var validator: EchoValidator?
    private var transport: (any WebSocketTransport)?
    private var connectTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var productionTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var watchdogTask: Task<Void, Never>?
    private var subscribers: [UUID: AsyncStream<MarketSnapshot>.Continuation] = [:]
    private var receivedCount = 0
    private var rejectedCount = 0
    private var lastReceivedAt: Date?
    private var errorMessage: String?
    private let logger = Logger(subsystem: "com.marketpulse.stocktracker", category: "Feed")

    init(stocks: [Stock] = StockCatalog.stocks,
         transportFactory: @escaping TransportFactory,
         generator: any PriceGenerating = PriceGenerator(),
         clock: any FeedClock = SystemFeedClock(),
         policy: FeedPolicy = FeedPolicy(),
         retryRandom: any RandomSource = SystemRandomSource()) {
        quotes = stocks.map { StockQuote(stock: $0) }
        self.transportFactory = transportFactory
        self.generator = generator
        self.clock = clock
        self.policy = policy
        self.retryRandom = retryRandom
    }

    func snapshots() -> AsyncStream<MarketSnapshot> {
        let id = UUID()
        let channel = AsyncStream<MarketSnapshot>.makeStream(bufferingPolicy: .bufferingNewest(1))
        subscribers[id] = channel.continuation
        channel.continuation.yield(currentSnapshot())
        channel.continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        return channel.stream
    }

    func currentSnapshot() -> MarketSnapshot {
        MarketSnapshot(quotes: quotes, state: state, wantsRunning: wantsRunning,
                       receivedCount: receivedCount, rejectedCount: rejectedCount,
                       lastReceivedAt: lastReceivedAt, errorMessage: errorMessage)
    }

    func start() {
        guard !wantsRunning else { return }
        wantsRunning = true
        failures = 0
        errorMessage = nil
        guard foreground else { state = .paused; publish(); return }
        launchConnection()
    }

    func stop() async {
        wantsRunning = false
        let old = invalidateConnection()
        state = .stopped
        errorMessage = nil
        publish()
        await old?.close()
    }

    func setForeground(_ value: Bool) async {
        guard foreground != value else { return }
        foreground = value
        if !value {
            let old = invalidateConnection()
            state = wantsRunning ? .paused : .stopped
            publish()
            await old?.close()
        } else if wantsRunning {
            failures = 0
            launchConnection()
        }
    }

    private func launchConnection() {
        guard wantsRunning, foreground, transport == nil else { return }
        let id = UUID()
        let connection = transportFactory()
        sessionID = id
        transport = connection
        sequence = 0
        validator = EchoValidator(sessionID: id, symbols: Set(quotes.map(\.id)))
        if failures == 0 { state = .connecting }
        publish()
        connectTask = Task { [weak self] in
            do {
                try await connection.connect()
                try Task.checkCancellation()
                await self?.connected(id: id, connection: connection)
            } catch {
                await self?.failed(id: id)
            }
        }
    }

    private func connected(id: UUID, connection: any WebSocketTransport) {
        guard isCurrent(id) else { return }
        connectTask = nil
        state = .connected
        errorMessage = nil
        logger.notice("WebSocket handshake confirmed")
        publish()
        receiveTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    let data = try await connection.receive()
                    try Task.checkCancellation()
                    guard let self else { return }
                    await self.accept(data, session: id)
                } catch {
                    await self?.failed(id: id)
                    return
                }
            }
        }
        let clock = self.clock
        let interval = policy.updateInterval
        productionTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    guard let data = try await self?.prepareMessage(session: id) else { return }
                    // I/O lives outside a strongly retained repository frame. A stalled send
                    // cannot keep the repository alive or block the independent echo watchdog.
                    try await connection.send(data)
                    try Task.checkCancellation()
                    try await clock.sleep(for: interval)
                } catch {
                    await self?.failed(id: id)
                    return
                }
            }
        }
        watchdogTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await clock.sleep(for: .seconds(1)) } catch { return }
                guard await self?.checkEchoHealth(session: id) == true else { return }
            }
        }
    }

    private enum ProductionError: Error { case tooManyPendingMessages }

    private func prepareMessage(session id: UUID) throws -> Data? {
        guard isCurrent(id), state == .connected else { return nil }
        guard (validator?.pendingCount ?? 0) < policy.maximumPendingMessages else {
            throw ProductionError.tooManyPendingMessages
        }
        let candidate = try generator.next(in: quotes)
        sequence += 1
        let message = PriceMessage(sessionId: id, messageId: UUID(), sequence: sequence,
                                   symbol: candidate.symbol, price: candidate.price.wireValue,
                                   sentAt: clock.now().formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
        let data = try MessageCodec.encode(message)
        // Register before send: a fast echo may arrive before send() returns.
        // Neither registration nor sending mutates a displayed quote.
        validator?.register(message)
        return data
    }

    private func checkEchoHealth(session id: UUID) async -> Bool {
        guard isCurrent(id), state == .connected else { return false }
        if let oldest = validator?.oldestSentAt, clock.now().timeIntervalSince(oldest) > policy.echoTimeout {
            await failed(id: id, unresponsive: true)
            return false
        }
        return true
    }

    private func accept(_ data: Data, session id: UUID) {
        guard isCurrent(id), state == .connected else { return }
        do {
            guard let candidate = try validator?.accept(data, now: clock.now(), maximumAge: policy.echoTimeout),
                  let index = quotes.firstIndex(where: { $0.id == candidate.symbol }) else { return }
            let receivedAt = clock.now()
            quotes[index].apply(price: candidate.price, at: receivedAt, sequence: try MessageCodec.decode(data).sequence)
            receivedCount += 1
            lastReceivedAt = receivedAt
            failures = 0 // Retry budget is reset by a validated echo, never by a handshake alone.
            logger.debug("Validated echo applied; count: \(self.receivedCount)")
            publish()
        } catch {
            rejectedCount += 1
            publish()
        }
    }

    private func failed(id: UUID, unresponsive: Bool = false) async {
        guard isCurrent(id) else { return }
        let old = invalidateConnection()
        failures += 1
        errorMessage = unresponsive ? "No valid echo arrived in time. Check your connection and try again." : "The echo service could not be reached. Check your connection and try again."
        if failures > policy.maximumRetries {
            wantsRunning = false
            state = .failed
            publish()
            await old?.close()
            return
        }
        let delay = policy.retryDelay(attempt: failures, jitterPercent: retryRandom.integer(in: 75...125))
        let token = UUID()
        retryID = token
        state = .reconnecting(attempt: failures, delaySeconds: max(1, Int(delay.components.seconds)))
        publish()
        let clock = self.clock
        retryTask = Task { [weak self] in
            // Closing this attempt is ordered before the next one is allowed to open.
            await old?.close()
            do { try await clock.sleep(for: delay) } catch { return }
            await self?.retry(token: token)
        }
    }

    private func retry(token: UUID) {
        guard retryID == token, wantsRunning, foreground, !Task.isCancelled else { return }
        retryID = nil
        retryTask = nil
        launchConnection()
    }

    /// Synchronous invalidation precedes every suspension point, so manual Stop always wins.
    private func invalidateConnection() -> (any WebSocketTransport)? {
        sessionID = nil
        retryID = nil
        validator = nil
        connectTask?.cancel(); connectTask = nil
        receiveTask?.cancel(); receiveTask = nil
        productionTask?.cancel(); productionTask = nil
        retryTask?.cancel(); retryTask = nil
        watchdogTask?.cancel(); watchdogTask = nil
        let previous = transport
        transport = nil
        return previous
    }

    private func isCurrent(_ id: UUID) -> Bool { wantsRunning && foreground && sessionID == id }
    private func publish() { let value = currentSnapshot(); subscribers.values.forEach { $0.yield(value) } }
    private func removeSubscriber(_ id: UUID) { subscribers.removeValue(forKey: id) }

    deinit {
        connectTask?.cancel()
        receiveTask?.cancel()
        productionTask?.cancel()
        retryTask?.cancel()
        watchdogTask?.cancel()
        if let transport { Task { await transport.close() } }
        subscribers.values.forEach { $0.finish() }
        // Explicit close also releases transports held by suspended receive/send tasks.
    }
}

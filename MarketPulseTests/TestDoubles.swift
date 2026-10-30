import Foundation
import Synchronization
@testable import MarketPulse

actor FakeTransport: WebSocketTransport {
    enum Failure: Error { case disconnected, concurrentReceive }
    private var sender: CheckedContinuation<Void, any Error>?
    private let suspendSends: Bool
    private var handshake: CheckedContinuation<Void, any Error>?
    private var receiver: CheckedContinuation<Data, any Error>?
    private var queue: [Data] = []
    private var closed = false
    private let autoOpen: Bool
    private let completesHandshakeAfterClose: Bool
    private(set) var connectCount = 0
    private(set) var completedHandshakeCount = 0
    private(set) var closeCount = 0
    private(set) var activeReceives = 0
    private(set) var maximumConcurrentReceives = 0
    private(set) var receiveCount = 0
    private(set) var sent: [Data] = []

    init(autoOpen: Bool = false, suspendSends: Bool = false, completesHandshakeAfterClose: Bool = false) {
        self.autoOpen = autoOpen
        self.suspendSends = suspendSends
        self.completesHandshakeAfterClose = completesHandshakeAfterClose
    }
    func connect() async throws {
        connectCount += 1
        closed = false
        if !autoOpen { try await withCheckedThrowingContinuation { handshake = $0 } }
        completedHandshakeCount += 1
    }
    func open() { handshake?.resume(); handshake = nil }
    func send(_ data: Data) async throws {
        guard !closed else { throw Failure.disconnected }
        sent.append(data)
        if suspendSends { try await withCheckedThrowingContinuation { sender = $0 } }
    }
    func receive() async throws -> Data {
        guard !closed else { throw Failure.disconnected }
        receiveCount += 1
        activeReceives += 1
        maximumConcurrentReceives = max(maximumConcurrentReceives, activeReceives)
        defer { activeReceives -= 1 }
        guard activeReceives == 1 else { throw Failure.concurrentReceive }
        if !queue.isEmpty { return queue.removeFirst() }
        return try await withCheckedThrowingContinuation { receiver = $0 }
    }
    func deliver(_ data: Data) {
        if let receiver { self.receiver = nil; receiver.resume(returning: data) }
        else { queue.append(data) }
    }
    func failReceive() {
        receiver?.resume(throwing: Failure.disconnected)
        receiver = nil
    }
    func close() {
        guard !closed else { return }
        closed = true
        closeCount += 1
        sender?.resume(throwing: CancellationError()); sender = nil
        // An opt-in adversarial peer deliberately completes its upgrade after close.
        // This exercises repository cancellation/session guards rather than the fake's cleanup.
        if !completesHandshakeAfterClose {
            handshake?.resume(throwing: CancellationError()); handshake = nil
        }
        receiver?.resume(throwing: CancellationError()); receiver = nil
        queue.removeAll()
    }
}

actor ManualFeedClock: FeedClock {
    private var waiters: [UUID: CheckedContinuation<Void, any Error>] = [:]
    nonisolated private let instant = Mutex(Date(timeIntervalSince1970: 1_790_000_000))
    var pendingSleeps: Int { waiters.count }
    nonisolated func now() -> Date { instant.withLock { $0 } }
    func sleep(for duration: Duration) async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation { continuation in
                waiters[id] = continuation
            }
        } onCancel: {
            Task { await self.cancel(id) }
        }
    }
    func advance(by seconds: TimeInterval = 1) {
        instant.withLock { $0 = $0.addingTimeInterval(seconds) }
        let pending = waiters.values
        waiters.removeAll()
        pending.forEach { $0.resume() }
    }
    private func cancel(_ id: UUID) { waiters.removeValue(forKey: id)?.resume(throwing: CancellationError()) }
}


final class TransportPool: Sendable {
    private let transports: Mutex<[FakeTransport]>
    init(_ transports: [FakeTransport]) { self.transports = Mutex(transports) }
    func next() -> any WebSocketTransport { transports.withLock { $0.removeFirst() } }
}

actor FailingTransport: WebSocketTransport {
    private(set) var attempts = 0
    func connect() throws { attempts += 1; throw FakeTransport.Failure.disconnected }
    func send(_ data: Data) throws { throw FakeTransport.Failure.disconnected }
    func receive() throws -> Data { throw FakeTransport.Failure.disconnected }
    func close() {}
}

@MainActor
final class WeakRepositoryReference {
    weak var value: LiveMarketRepository?
    init(_ value: LiveMarketRepository?) { self.value = value }
}

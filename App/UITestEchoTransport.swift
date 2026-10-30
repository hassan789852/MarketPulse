#if DEBUG
import Foundation

/// Explicit, debug-only test fixture. Never selected by a normal launch or a Release build.
actor UITestEchoTransport: WebSocketTransport {
    enum FixtureError: Error { case disconnected }
    private var receiver: CheckedContinuation<Data, any Error>?
    private var queue: [Data] = []
    private var isOpen = false
    private let fails: Bool
    init(fails: Bool) { self.fails = fails }

    func connect() async throws {
        try await Task.sleep(for: .milliseconds(200))
        if fails { throw FixtureError.disconnected }
        isOpen = true
    }
    func send(_ data: Data) throws {
        guard isOpen else { throw FixtureError.disconnected }
        if let receiver { self.receiver = nil; receiver.resume(returning: data) }
        else { queue.append(data) }
    }
    func receive() async throws -> Data {
        guard isOpen else { throw FixtureError.disconnected }
        let data: Data
        if !queue.isEmpty { data = queue.removeFirst() }
        else { data = try await withCheckedThrowingContinuation { receiver = $0 } }
        try await Task.sleep(for: .milliseconds(150))
        guard isOpen else { throw FixtureError.disconnected }
        return data
    }
    func close() {
        isOpen = false
        receiver?.resume(throwing: CancellationError()); receiver = nil
        queue.removeAll()
    }
}
#endif

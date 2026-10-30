import Foundation

/// One transport instance per connection attempt. URLSession's delegate confirms the upgrade;
/// `resume()` alone never reports success. All mutable networking state is actor-isolated.
actor URLSessionWebSocketTransport: WebSocketTransport {
    enum TransportError: Error { case closed, handshakeTimeout, oversized }
    private enum State { case idle, opening, open, closed }
    private enum Event: Sendable { case opened, closed, failed }

    private final class Delegate: NSObject, URLSessionWebSocketDelegate {
        let events: AsyncStream<Event>.Continuation
        init(events: AsyncStream<Event>.Continuation) { self.events = events }

        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
            events.yield(.opened)
        }
        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            events.yield(.closed)
        }
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
            if error != nil { events.yield(.failed) }
        }
    }

    private let endpoint: URL
    private var state: State = .idle
    private var session: URLSession?
    private var socket: URLSessionWebSocketTask?
    private var opening: CheckedContinuation<Void, any Error>?
    private var eventTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var events: AsyncStream<Event>.Continuation?

    init(endpoint: URL) { self.endpoint = endpoint }

    func connect() async throws {
        guard state == .idle else { throw TransportError.closed }
        try Task.checkCancellation()
        state = .opening
        let channel = AsyncStream<Event>.makeStream(bufferingPolicy: .bufferingNewest(8))
        events = channel.continuation
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 12
        // Keep the system resource lifetime for this long-lived connection. A short
        // resource timeout would close a healthy socket; handshake and echo deadlines
        // are independently bounded by the transport and repository watchdogs.
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let session = URLSession(configuration: configuration, delegate: Delegate(events: channel.continuation), delegateQueue: queue)
        self.session = session
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 12
        let socket = session.webSocketTask(with: request)
        socket.maximumMessageSize = MessageCodec.maximumBytes
        self.socket = socket
        eventTask = Task { [weak self] in
            for await event in channel.stream {
                guard !Task.isCancelled else { return }
                await self?.handle(event)
            }
        }
        timeoutTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(12)) } catch { return }
            await self?.timeout()
        }
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation { continuation in
                opening = continuation
                socket.resume()
            }
        } onCancel: {
            Task { await self.close() }
        }
        try Task.checkCancellation()
    }

    func send(_ data: Data) async throws {
        guard state == .open, let socket else { throw TransportError.closed }
        guard data.count <= MessageCodec.maximumBytes else { throw TransportError.oversized }
        // JSON text frames make the wire protocol readable in ordinary WebSocket tooling.
        try await socket.send(.string(String(decoding: data, as: UTF8.self)))
        try Task.checkCancellation()
        guard state == .open else { throw TransportError.closed }
    }

    func receive() async throws -> Data {
        guard state == .open, let socket else { throw TransportError.closed }
        let message = try await socket.receive()
        try Task.checkCancellation()
        guard state == .open else { throw TransportError.closed }
        let data: Data
        switch message {
        case .data(let value): data = value
        case .string(let value): data = Data(value.utf8)
        @unknown default: throw TransportError.closed
        }
        guard data.count <= MessageCodec.maximumBytes else { throw TransportError.oversized }
        return data
    }

    func close() { finish(with: CancellationError()) }

    private func handle(_ event: Event) {
        switch event {
        case .opened:
            guard state == .opening else { return }
            state = .open
            timeoutTask?.cancel(); timeoutTask = nil
            opening?.resume(); opening = nil
        case .closed, .failed: finish(with: TransportError.closed)
        }
    }

    private func timeout() {
        guard state == .opening else { return }
        finish(with: TransportError.handshakeTimeout)
    }

    private func finish(with error: any Error) {
        guard state != .closed else { return }
        state = .closed
        timeoutTask?.cancel(); timeoutTask = nil
        eventTask?.cancel(); eventTask = nil
        events?.finish(); events = nil
        socket?.cancel(with: .goingAway, reason: nil); socket = nil
        session?.invalidateAndCancel(); session = nil
        opening?.resume(throwing: error); opening = nil
    }

    deinit {
        timeoutTask?.cancel()
        eventTask?.cancel()
        events?.finish()
        socket?.cancel(with: .goingAway, reason: nil)
        session?.invalidateAndCancel()
    }
}

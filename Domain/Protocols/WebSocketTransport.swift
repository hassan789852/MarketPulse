import Foundation

protocol WebSocketTransport: Sendable {
    /// Returns only once the server's WebSocket upgrade handshake succeeds.
    func connect() async throws
    func send(_ data: Data) async throws
    func receive() async throws -> Data
    func close() async
}

typealias TransportFactory = @Sendable () -> any WebSocketTransport

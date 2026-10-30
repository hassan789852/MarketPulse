import Foundation

protocol MarketRepository: Sendable {
    func snapshots() async -> AsyncStream<MarketSnapshot>
    func start() async
    func stop() async
    func setForeground(_ foreground: Bool) async
}

import Foundation

enum FeedState: Sendable, Equatable {
    case stopped
    case connecting
    case connected
    case reconnecting(attempt: Int, delaySeconds: Int)
    case paused
    case failed
}

struct MarketSnapshot: Sendable, Equatable {
    let quotes: [StockQuote]
    let state: FeedState
    let wantsRunning: Bool
    let receivedCount: Int
    let rejectedCount: Int
    let lastReceivedAt: Date?
    let errorMessage: String?
}

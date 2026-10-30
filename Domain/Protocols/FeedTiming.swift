import Foundation

protocol FeedClock: Sendable {
    func now() -> Date
    func sleep(for duration: Duration) async throws
}

struct SystemFeedClock: FeedClock {
    func now() -> Date { Date() }
    func sleep(for duration: Duration) async throws { try await Task.sleep(for: duration) }
}

struct FeedPolicy: Sendable {
    var updateInterval: Duration = .seconds(1)
    var echoTimeout: TimeInterval = 15
    var maximumRetries: Int = 5
    var maximumPendingMessages: Int = 16

    func retryDelay(attempt: Int, jitterPercent: Int) -> Duration {
        let baseMilliseconds = min(16_000, 1_000 << min(max(attempt - 1, 0), 4))
        return .milliseconds(baseMilliseconds * min(125, max(75, jitterPercent)) / 100)
    }
}

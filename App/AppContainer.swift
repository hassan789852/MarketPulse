import Foundation

@MainActor
enum AppContainer {
    static func makeStore() -> MarketStore {
        let repository: LiveMarketRepository
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            let failure = ProcessInfo.processInfo.arguments.contains("--ui-test-failure")
            repository = LiveMarketRepository(
                transportFactory: { UITestEchoTransport(fails: failure) },
                generator: PriceGenerator(random: SeededRandomSource(seed: 42)),
                policy: FeedPolicy(updateInterval: .milliseconds(800), maximumRetries: failure ? 0 : 5)
            )
        } else {
            repository = liveRepository()
        }
        #else
        repository = liveRepository()
        #endif
        return MarketStore(repository: repository)
    }

    private static func liveRepository() -> LiveMarketRepository {
        guard let endpoint = URL(string: "wss://ws.postman-echo.com/raw") else {
            preconditionFailure("Invalid built-in WebSocket endpoint")
        }
        return LiveMarketRepository(transportFactory: { URLSessionWebSocketTransport(endpoint: endpoint) })
    }
}

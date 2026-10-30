import Foundation

/// Opt-in real-network diagnostic using the exact production transport and repository.
/// Build instructions are in README. This is not part of the network-independent CI suite.
@main
struct VerifyEcho {
    enum DiagnosticError: Error { case invalidURL, timedOut, stoppedEarly }
    static func main() async throws {
        guard let endpoint = URL(string: "wss://ws.postman-echo.com/raw") else { throw DiagnosticError.invalidURL }
        let extended = ProcessInfo.processInfo.arguments.contains("--extended")
        let requiredEchoes = extended ? 75 : 3
        let repository = LiveMarketRepository(transportFactory: { URLSessionWebSocketTransport(endpoint: endpoint) })
        let snapshots = await repository.snapshots()
        await repository.start()
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await snapshot in snapshots {
                        print("state=\(snapshot.state), validatedEchoes=\(snapshot.receivedCount), rejected=\(snapshot.rejectedCount)")
                        if snapshot.receivedCount >= requiredEchoes { return }
                        if Task.isCancelled { throw CancellationError() }
                    }
                    throw DiagnosticError.stoppedEarly
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(extended ? 110 : 25))
                    throw DiagnosticError.timedOut
                }
                defer { group.cancelAll() }
                try await group.next()
            }
            await repository.stop()
            let snapshot = await repository.currentSnapshot()
            guard snapshot.state == .stopped else { throw DiagnosticError.stoppedEarly }
            print("PASS: production handshake, \(requiredEchoes) validated server echoes, and Stop verified.")
        } catch {
            await repository.stop()
            throw error
        }
    }
}

import Foundation
import Testing
@testable import MarketPulse

struct RepositoryTests {
    @Test func startsOnlyAfterHandshakeAndAppliesOnlyAnEcho() async throws {
        let transport = FakeTransport()
        let clock = ManualFeedClock()
        let repo = makeRepository(transport: transport, clock: clock)
        await repo.start()
        await repo.start()
        try await eventually { await transport.connectCount == 1 }
        #expect(await repo.currentSnapshot().state == .connecting)
        #expect(await transport.sent.isEmpty)
        await transport.open()
        try await eventually { await transport.sent.count == 1 }
        let sent = try #require(await transport.sent.first)
        let before = await repo.currentSnapshot()
        #expect(before.state == .connected)
        #expect(before.quotes[0].price == before.quotes[0].stock.referencePrice)
        #expect(before.receivedCount == 0)
        await transport.deliver(sent)
        try await eventually { await repo.currentSnapshot().receivedCount == 1 }
        let after = await repo.currentSnapshot()
        let message = try MessageCodec.decode(sent)
        #expect(after.quotes[0].price == (try Price(message.price)))
        #expect(after.quotes[0].price != before.quotes[0].price)
        await transport.deliver(sent)
        try await eventually { await repo.currentSnapshot().rejectedCount == 1 }
        #expect(await repo.currentSnapshot().receivedCount == 1)
        await repo.stop()
        #expect(await transport.closeCount == 1)
        #expect(await repo.currentSnapshot().state == .stopped)
        await transport.deliver(sent)
        await Task.yield()
        #expect(await repo.currentSnapshot().receivedCount == 1)
    }

    @Test func stopDuringHandshakePreventsLateOpenAndProduction() async throws {
        let transport = FakeTransport(completesHandshakeAfterClose: true)
        let repo = makeRepository(transport: transport)
        await repo.start()
        try await eventually { await transport.connectCount == 1 }
        await repo.stop()
        await transport.open()
        try await eventually { await transport.completedHandshakeCount == 1 }
        for _ in 0..<20 { await Task.yield() }
        #expect(await repo.currentSnapshot().state == .stopped)
        #expect(await transport.sent.isEmpty)
        #expect(await transport.closeCount == 1)
        #expect(await transport.receiveCount == 0)
    }

    @Test func lateHandshakeCannotReplaceARestartedSession() async throws {
        let first = FakeTransport(completesHandshakeAfterClose: true)
        let second = FakeTransport(autoOpen: true)
        let pool = TransportPool([first, second])
        let repo = LiveMarketRepository(transportFactory: { pool.next() }, clock: ManualFeedClock())
        await repo.start()
        try await eventually { await first.connectCount == 1 }
        await repo.stop()
        await repo.start()
        try await eventually { await second.sent.count == 1 }
        // Complete the cancelled upgrade only after the replacement session is active.
        await first.open()
        try await eventually { await first.completedHandshakeCount == 1 }
        let fresh = try #require(await second.sent.first)
        await second.deliver(fresh)
        try await eventually { await repo.currentSnapshot().receivedCount == 1 }
        #expect(await repo.currentSnapshot().state == .connected)
        #expect(await first.sent.isEmpty)
        #expect(await first.receiveCount == 0)
        #expect(await first.closeCount == 1)
        #expect(await second.connectCount == 1)
        await repo.stop()
    }

    @Test func repeatedStartKeepsOneReceiveLoopAndOneProducer() async throws {
        let transport = FakeTransport(autoOpen: true)
        let clock = ManualFeedClock()
        let repo = makeRepository(transport: transport, clock: clock)
        await repo.start()
        for expected in 1...4 {
            try await eventually {
                let sends = await transport.sent.count
                let sleeps = await clock.pendingSleeps
                let receives = await transport.activeReceives
                return sends == expected && sleeps == 2 && receives == 1
            }
            for _ in 0..<5 { await repo.start() }
            let message = try #require(await transport.sent.last)
            await transport.deliver(message)
            try await eventually { await repo.currentSnapshot().receivedCount == expected }
            #expect(await transport.sent.count == expected)
            #expect(await transport.connectCount == 1)
            #expect(await transport.maximumConcurrentReceives == 1)
            if expected < 4 { await clock.advance() }
        }
        await repo.stop()
        try await eventually { await transport.activeReceives == 0 }
        #expect(await transport.closeCount == 1)
    }

    @Test func disconnectSchedulesRetryAndManualStopWins() async throws {
        let transport = FakeTransport(autoOpen: true)
        let clock = ManualFeedClock()
        let repo = makeRepository(transport: transport, clock: clock)
        await repo.start()
        try await eventually { await transport.sent.count == 1 }
        await transport.failReceive()
        try await eventually {
            if case .reconnecting = await repo.currentSnapshot().state { return true }
            return false
        }
        await repo.stop()
        await clock.advance()
        for _ in 0..<20 { await Task.yield() }
        #expect(await transport.connectCount == 1)
        #expect(await repo.currentSnapshot().state == .stopped)
    }

    @Test func backgroundPreservesIntentButStopPreventsForegroundResume() async throws {
        let transport = FakeTransport(autoOpen: true)
        let repo = makeRepository(transport: transport)
        await repo.start()
        try await eventually { await transport.sent.count == 1 }
        await repo.setForeground(false)
        #expect(await repo.currentSnapshot().state == .paused)
        #expect(await repo.currentSnapshot().wantsRunning)
        await repo.stop()
        await repo.setForeground(true)
        #expect(await repo.currentSnapshot().state == .stopped)
        #expect(await transport.connectCount == 1)
    }

    @Test func reconnectUsesANewSessionAndRejectsOldSessionEchoes() async throws {
        let first = FakeTransport(autoOpen: true)
        let second = FakeTransport(autoOpen: true)
        let pool = TransportPool([first, second])
        let clock = ManualFeedClock()
        let repo = LiveMarketRepository(transportFactory: { pool.next() }, clock: clock)
        await repo.start()
        try await eventually { await first.sent.count == 1 }
        let stale = try #require(await first.sent.first)
        await first.failReceive()
        try await eventually {
            let closed = await first.closeCount
            let sleeps = await clock.pendingSleeps
            return closed == 1 && sleeps == 1
        }
        await clock.advance()
        try await eventually { await second.sent.count == 1 }
        let fresh = try #require(await second.sent.first)
        #expect(try MessageCodec.decode(stale).sessionId != MessageCodec.decode(fresh).sessionId)
        await second.deliver(stale)
        try await eventually { await repo.currentSnapshot().rejectedCount == 1 }
        #expect(await repo.currentSnapshot().receivedCount == 0)
        await second.deliver(fresh)
        try await eventually { await repo.currentSnapshot().receivedCount == 1 }
        #expect(await first.closeCount == 1)
        await repo.stop()
        #expect(await second.closeCount == 1)
    }

    @Test func retriesHaveAFiniteBudgetAndCanBeManuallyRestarted() async throws {
        let transport = FailingTransport()
        let clock = ManualFeedClock()
        let repo = LiveMarketRepository(transportFactory: { transport }, clock: clock, policy: FeedPolicy(maximumRetries: 2))
        await repo.start()
        for expected in 1...2 {
            try await eventually {
                let attempts = await transport.attempts
                let sleeps = await clock.pendingSleeps
                return attempts == expected && sleeps == 1
            }
            await clock.advance()
        }
        try await eventually { await repo.currentSnapshot().state == .failed }
        #expect(await transport.attempts == 3)
        #expect(await repo.currentSnapshot().wantsRunning == false)
        await clock.advance()
        #expect(await transport.attempts == 3)
        await repo.start()
        try await eventually { await transport.attempts == 4 }
        await repo.stop()
    }

    @Test func silentConnectionTimesOutInsteadOfClaimingLiveForever() async throws {
        let transport = FakeTransport(autoOpen: true)
        let clock = ManualFeedClock()
        let repo = makeRepository(transport: transport, clock: clock)
        await repo.start()
        try await eventually {
            let count = await transport.sent.count
            let sleeps = await clock.pendingSleeps
            return count == 1 && sleeps == 2
        }
        await clock.advance(by: 20)
        try await eventually {
            if case .reconnecting = await repo.currentSnapshot().state { return true }
            return false
        }
        #expect(await repo.currentSnapshot().receivedCount == 0)
        #expect(await repo.currentSnapshot().quotes[0].history.isEmpty)
        await repo.stop()
    }

    @Test func foregroundResumesOnlyThePreviouslyRequestedFeed() async throws {
        let first = FakeTransport(autoOpen: true)
        let second = FakeTransport(autoOpen: true)
        let pool = TransportPool([first, second])
        let repo = LiveMarketRepository(transportFactory: { pool.next() }, clock: ManualFeedClock())
        await repo.start()
        try await eventually { await first.sent.count == 1 }
        await repo.setForeground(false)
        #expect(await first.closeCount == 1)
        #expect(await repo.currentSnapshot().wantsRunning)
        await repo.setForeground(true)
        try await eventually { await second.sent.count == 1 }
        #expect(await repo.currentSnapshot().state == .connected)
        await repo.stop()
    }

    @MainActor @Test(arguments: [false, true])
    func releasingRepositoryClosesSuspendedIO(suspendedSend: Bool) async throws {
        let transport = FakeTransport(autoOpen: true, suspendSends: suspendedSend)
        var repository: LiveMarketRepository? = LiveMarketRepository(transportFactory: { transport }, clock: ManualFeedClock())
        let released = WeakRepositoryReference(repository)
        await repository?.start()
        try await eventually { await transport.sent.count == 1 }
        repository = nil
        do {
            try await eventually { await transport.closeCount == 1 }
        } catch {
            await transport.close()
            throw error
        }
        #expect(released.value == nil)
    }

    @Test func suspendedSendStillHasAnIndependentEchoDeadline() async throws {
        let transport = FakeTransport(autoOpen: true, suspendSends: true)
        let clock = ManualFeedClock()
        let repository = makeRepository(transport: transport, clock: clock)
        await repository.start()
        try await eventually { await transport.sent.count == 1 }
        try await eventually { await clock.pendingSleeps == 1 }
        // The clock advances independently of a send that has never returned.
        await clock.advance(by: 20)
        do {
            try await eventually {
                if case .reconnecting = await repository.currentSnapshot().state { return true }
                return false
            }
        } catch {
            await repository.stop()
            throw error
        }
        #expect(await transport.closeCount == 1)
        #expect(await repository.currentSnapshot().receivedCount == 0)
        await repository.stop()
    }

    private func makeRepository(transport: FakeTransport, clock: ManualFeedClock = ManualFeedClock()) -> LiveMarketRepository {
        LiveMarketRepository(transportFactory: { transport }, generator: PriceGenerator(random: SeededRandomSource(seed: 42)), clock: clock, retryRandom: SeededRandomSource(seed: 1))
    }
}

func eventually(_ predicate: @escaping @Sendable () async -> Bool) async throws {
    for _ in 0..<2_000 {
        if await predicate() { return }
        try await Task.sleep(for: .milliseconds(1))
    }
    throw TestTimeout.conditionNotMet
}

enum TestTimeout: Error { case conditionNotMet }

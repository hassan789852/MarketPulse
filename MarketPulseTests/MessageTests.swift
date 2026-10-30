import Foundation
import Testing
@testable import MarketPulse

struct MessageTests {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    @Test func roundTripAndAcceptOnlyRegisteredEcho() throws {
        let message = makeMessage()
        let data = try MessageCodec.encode(message)
        #expect(try MessageCodec.decode(data) == message)
        var validator = EchoValidator(sessionID: message.sessionId, symbols: ["AAPL"])
        #expect(throws: (any Error).self) { try validator.accept(data, now: now) }
        validator.register(message)
        let update = try validator.accept(data, now: now)
        #expect(update.symbol == "AAPL")
        #expect(update.price == (try Price("190.50")))
        #expect(throws: (any Error).self) { try validator.accept(data, now: now) }
    }

    @Test func rejectsMalformedAndOversizedMessages() {
        for data in [Data("{".utf8), Data(repeating: 65, count: 4_097)] {
            #expect(throws: (any Error).self) { try MessageCodec.decode(data) }
        }
    }

    @Test func validatesContractAndSessionAndExactSentPayload() throws {
        let good = makeMessage()
        let badMessages = [
            makeMessage(schemaVersion: 2), makeMessage(type: "trade"), makeMessage(symbol: "UNKNOWN"),
            makeMessage(price: "-4"), makeMessage(price: "NaN"), makeMessage(price: "0"),
            makeMessage(price: "1.234"), makeMessage(session: UUID()),
            makeMessage(id: UUID()), makeMessage(sequence: 0), makeMessage(sentAt: "invalid")
        ]
        for bad in badMessages {
            var validator = EchoValidator(sessionID: good.sessionId, symbols: ["AAPL"])
            validator.register(good)
            #expect(throws: (any Error).self) { try validator.accept(MessageCodec.encode(bad), now: now) }
        }
        var validator = EchoValidator(sessionID: good.sessionId, symbols: ["AAPL"])
        validator.register(good)
        #expect(throws: (any Error).self) { try validator.accept(MessageCodec.encode(good), now: now.addingTimeInterval(61)) }
    }

    @Test func rejectsOutOfOrderEchoes() throws {
        let one = makeMessage()
        let two = makeMessage(id: UUID(), sequence: 2)
        var validator = EchoValidator(sessionID: one.sessionId, symbols: ["AAPL"])
        validator.register(one)
        validator.register(two)
        _ = try validator.accept(MessageCodec.encode(two), now: now)
        #expect(throws: (any Error).self) { try validator.accept(MessageCodec.encode(one), now: now) }
        #expect(validator.pendingCount == 0)
    }

    private func makeMessage(schemaVersion: Int = 1, type: String = "price_update", symbol: String = "AAPL", price: String = "190.50", session: UUID? = nil, id: UUID? = nil, sequence: UInt64 = 1, sentAt: String? = nil) -> PriceMessage {
        PriceMessage(schemaVersion: schemaVersion, type: type,
                     sessionId: session ?? UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                     messageId: id ?? UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                     sequence: sequence, symbol: symbol, price: price,
                     sentAt: sentAt ?? now.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
    }
}

import Foundation

struct PriceMessage: Codable, Sendable, Equatable {
    var schemaVersion: Int = 1
    var type: String = "price_update"
    let sessionId: UUID
    let messageId: UUID
    let sequence: UInt64
    let symbol: String
    let price: String
    let sentAt: String
}

enum MessageCodec {
    static let maximumBytes = 4_096
    enum ValidationError: Error { case oversized, unsupported, unknownSymbol, stale, unsolicited }

    static func encode(_ message: PriceMessage) throws -> Data { try JSONEncoder().encode(message) }
    static func decode(_ data: Data) throws -> PriceMessage {
        guard data.count <= maximumBytes else { throw ValidationError.oversized }
        return try JSONDecoder().decode(PriceMessage.self, from: data)
    }
}

/// A bounded ledger of sent candidates. Receiving valid JSON is not sufficient: it must echo
/// an exact outstanding message from this connection, in strictly increasing sequence order.
struct EchoValidator: Sendable {
    let sessionID: UUID
    let symbols: Set<String>
    private var pending: [UUID: PriceMessage] = [:]
    private var lastSequence: UInt64 = 0

    init(sessionID: UUID, symbols: Set<String>) {
        self.sessionID = sessionID
        self.symbols = symbols
    }

    var pendingCount: Int { pending.count }
    var oldestSentAt: Date? { pending.values.compactMap { Self.date($0.sentAt) }.min() }

    mutating func register(_ message: PriceMessage) { pending[message.messageId] = message }

    mutating func accept(_ data: Data, now: Date, maximumAge: TimeInterval = 15) throws -> PriceCandidate {
        let message = try MessageCodec.decode(data)
        guard message.schemaVersion == 1, message.type == "price_update" else { throw MessageCodec.ValidationError.unsupported }
        guard symbols.contains(message.symbol) else { throw MessageCodec.ValidationError.unknownSymbol }
        let price = try Price(message.price)
        guard message.sessionId == sessionID, message.sequence > lastSequence,
              let sent = Self.date(message.sentAt),
              now.timeIntervalSince(sent) >= -5, now.timeIntervalSince(sent) <= maximumAge else {
            throw MessageCodec.ValidationError.stale
        }
        guard pending[message.messageId] == message else { throw MessageCodec.ValidationError.unsolicited }
        lastSequence = message.sequence
        pending = pending.filter { $0.value.sequence > message.sequence }
        return PriceCandidate(symbol: message.symbol, price: price)
    }

    private static func date(_ string: String) -> Date? {
        try? Date(string, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }
}

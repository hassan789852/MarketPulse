import Foundation

/// Validated USD amount. Wire prices are exact decimal strings; calculations use bankers' rounding.
struct Price: Sendable, Equatable, Comparable, Hashable {
    enum ValidationError: Error { case invalidPrice }
    static let maximum: Decimal = 1_000_000
    let value: Decimal

    init(_ wireValue: String) throws {
        guard wireValue.utf8.count <= 10,
              wireValue.range(of: #"\A[0-9]+(?:\.[0-9]{1,2})?\z"#, options: .regularExpression) != nil,
              let decimal = Decimal(string: wireValue, locale: Locale(identifier: "en_US_POSIX")) else {
            throw ValidationError.invalidPrice
        }
        try self.init(rounding: decimal)
    }

    init(rounding amount: Decimal) throws {
        guard !amount.isNaN, amount > 0, amount <= Self.maximum else { throw ValidationError.invalidPrice }
        var input = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &input, 2, .bankers)
        guard rounded >= Decimal(1) / 100 else { throw ValidationError.invalidPrice }
        value = rounded
    }

    /// Compile-time catalog constants, expressed in cents without floating-point literals.
    init(cents: Int) {
        precondition(cents > 0 && cents <= 100_000_000)
        value = Decimal(cents) / 100
    }

    var wireValue: String {
        var decimal = value
        let raw = NSDecimalString(&decimal, Locale(identifier: "en_US_POSIX"))
        let pieces = raw.split(separator: ".")
        let fraction = pieces.count == 2 ? String(pieces[1]) : ""
        return String(pieces[0]) + "." + fraction.padding(toLength: 2, withPad: "0", startingAt: 0)
    }

    static func < (lhs: Price, rhs: Price) -> Bool { lhs.value < rhs.value }
}

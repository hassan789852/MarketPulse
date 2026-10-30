import Foundation

protocol RandomSource: Sendable {
    mutating func integer(in range: ClosedRange<Int>) -> Int
}

struct SystemRandomSource: RandomSource {
    mutating func integer(in range: ClosedRange<Int>) -> Int { Int.random(in: range) }
}

/// Repeatable non-cryptographic randomness, exclusively for simulations and tests.
struct SeededRandomSource: RandomSource {
    var seed: UInt64
    mutating func integer(in range: ClosedRange<Int>) -> Int {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return range.lowerBound + Int((seed >> 32) % UInt64(range.count))
    }
}

struct PriceCandidate: Equatable, Sendable {
    let symbol: String
    let price: Price
}

protocol PriceGenerating: Sendable {
    mutating func next(in quotes: [StockQuote]) throws -> PriceCandidate
}

struct PriceGenerator: PriceGenerating {
    enum GenerationError: Error { case emptyCatalog }
    private var cursor = 0
    private var random: any RandomSource

    init(random: any RandomSource = SystemRandomSource()) { self.random = random }

    /// Round-robin selection is fair: each symbol is visited exactly once per cycle.
    mutating func next(in quotes: [StockQuote]) throws -> PriceCandidate {
        guard !quotes.isEmpty else { throw GenerationError.emptyCatalog }
        let quote = quotes[cursor % quotes.count]
        cursor = (cursor + 1) % quotes.count
        let basisPoints = random.integer(in: -80...80)
        let proposed = quote.price.value * (1 + Decimal(basisPoints) / 10_000)
        let bounded = min(Price.maximum, max(Decimal(1) / 100, proposed))
        return PriceCandidate(symbol: quote.id, price: try Price(rounding: bounded))
    }
}

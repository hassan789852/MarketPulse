import Foundation

struct Stock: Identifiable, Sendable, Equatable {
    let id: String
    let company: String
    let description: String
    let referencePrice: Price
}

struct PricePoint: Identifiable, Sendable, Equatable {
    let id: UUID
    let sequence: UInt64
    let time: Date
    let price: Price
}

struct StockQuote: Identifiable, Sendable, Equatable {
    static let historyLimit = 120
    let stock: Stock
    private(set) var price: Price
    private(set) var updatedAt: Date?
    private(set) var history: [PricePoint] = []

    var id: String { stock.id }
    var absoluteChange: Decimal { price.value - stock.referencePrice.value }
    /// A ratio, e.g. 0.014 means +1.4%, always relative to the fictional seed.
    var relativeChange: Decimal { absoluteChange / stock.referencePrice.value }

    init(stock: Stock, price: Price? = nil) {
        self.stock = stock
        self.price = price ?? stock.referencePrice
    }

    mutating func apply(price: Price, at timestamp: Date, sequence: UInt64) {
        self.price = price
        updatedAt = timestamp
        history.append(PricePoint(id: UUID(), sequence: sequence, time: timestamp, price: price))
        if history.count > Self.historyLimit { history.removeFirst(history.count - Self.historyLimit) }
    }
}

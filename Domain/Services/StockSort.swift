import Foundation

enum SortMetric: String, Sendable, CaseIterable { case price, change }
enum SortDirection: String, Sendable, CaseIterable { case ascending, descending }

struct StockSort: Sendable, Equatable {
    var metric: SortMetric = .price
    var direction: SortDirection = .descending

    func precedes(_ lhs: StockQuote, _ rhs: StockQuote) -> Bool {
        let left = metric == .price ? lhs.price.value : lhs.relativeChange
        let right = metric == .price ? rhs.price.value : rhs.relativeChange
        if left == right { return lhs.id < rhs.id }
        return direction == .ascending ? left < right : left > right
    }

    func sorted(_ quotes: [StockQuote]) -> [StockQuote] { quotes.sorted(by: precedes) }
}

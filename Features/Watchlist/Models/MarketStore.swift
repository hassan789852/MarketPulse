import Foundation
import Observation

@MainActor @Observable
final class QuoteModel: Identifiable {
    let id: String
    private(set) var quote: StockQuote
    init(_ quote: StockQuote) { id = quote.id; self.quote = quote }
    func apply(_ value: StockQuote) { if quote != value { quote = value } }
}

/// UI projection, not another quote producer. Rows and details retain the same QuoteModel.
@MainActor @Observable
final class MarketStore {
    private(set) var rows: [QuoteModel]
    private(set) var state: FeedState = .stopped
    private(set) var wantsRunning = false
    private(set) var receivedCount = 0
    private(set) var rejectedCount = 0
    private(set) var lastReceivedAt: Date?
    private(set) var errorMessage: String?
    var sort = StockSort()
    var selection: String?
    @ObservationIgnored private let repository: any MarketRepository
    @ObservationIgnored private var bySymbol: [String: QuoteModel]
    @ObservationIgnored private var observing = false

    init(repository: any MarketRepository, stocks: [Stock] = StockCatalog.stocks) {
        self.repository = repository
        let rows = stocks.map { QuoteModel(StockQuote(stock: $0)) }
        self.rows = rows
        bySymbol = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
    }

    var sortedRows: [QuoteModel] { rows.sorted { sort.precedes($0.quote, $1.quote) } }
    func row(for symbol: String) -> QuoteModel? { bySymbol[symbol] }

    func observe() async {
        guard !observing else { return }
        observing = true
        defer { observing = false }
        let stream = await repository.snapshots()
        for await snapshot in stream {
            guard !Task.isCancelled else { return }
            apply(snapshot)
        }
    }

    func start() async { await repository.start() }
    func stop() async { await repository.stop() }
    func setForeground(_ foreground: Bool) async { await repository.setForeground(foreground) }

    private func apply(_ snapshot: MarketSnapshot) {
        state = snapshot.state
        wantsRunning = snapshot.wantsRunning
        receivedCount = snapshot.receivedCount
        rejectedCount = snapshot.rejectedCount
        lastReceivedAt = snapshot.lastReceivedAt
        errorMessage = snapshot.errorMessage
        for quote in snapshot.quotes { bySymbol[quote.id]?.apply(quote) }
    }
}

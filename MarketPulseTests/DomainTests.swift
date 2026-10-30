import Foundation
import Testing
@testable import MarketPulse

struct DomainTests {
    @Test func catalogHasExactly25UniqueValidStocks() throws {
        let stocks = StockCatalog.stocks
        #expect(stocks.count == 25)
        #expect(Set(stocks.map(\.id)).count == 25)
        #expect(Set(stocks.map(\.id)) == Set("AAPL MSFT NVDA GOOGL AMZN META TSLA NFLX AMD INTC ORCL CRM ADBE PYPL UBER SHOP JPM BAC GS V MA DIS KO PEP WMT".split(separator: " ").map(String.init)))
        #expect(stocks.allSatisfy { $0.referencePrice.value > 0 && !$0.company.isEmpty && !$0.description.isEmpty })
    }

    @Test(arguments: [("110", "10", "0.1"), ("90", "-10", "-0.1"), ("100", "0", "0")])
    func changesAreRelativeToReference(input: (String, String, String)) throws {
        let stock = Stock(id: "TEST", company: "Test", description: "Test company", referencePrice: try Price("100"))
        let quote = StockQuote(stock: stock, price: try Price(input.0))
        #expect(quote.absoluteChange == Decimal(string: input.1))
        #expect(quote.relativeChange == Decimal(string: input.2))
    }

    @Test func roundsMoneyWithoutBinaryFloatingPoint() throws {
        #expect(try Price(rounding: Decimal(string: "12.345")!).value == Decimal(string: "12.34"))
        #expect(try Price(rounding: Decimal(string: "12.355")!).value == Decimal(string: "12.36"))
        #expect(try Price("0.10").value + Price("0.20").value == Price("0.30").value)
        #expect(try Price("189.42").wireValue == "189.42")
    }

    @Test(arguments: ["0", "-1", "NaN", "inf", "1e2", "1,23", "1.234", "12x", " 12", "1000000.01", "", ".5"])
    func rejectsInvalidWirePrices(_ value: String) {
        #expect(throws: Price.ValidationError.self) { try Price(value) }
    }

    @Test func rejectsInvalidComputedPrices() {
        #expect(throws: Price.ValidationError.self) { try Price(rounding: .nan) }
        #expect(throws: Price.ValidationError.self) { try Price(rounding: -1) }
        #expect(throws: Price.ValidationError.self) { try Price(rounding: Decimal(string: "0.001")!) }
    }

    @Test func sortingAndTieBreakingRemainDeterministic() throws {
        let stocks = [
            Stock(id: "B", company: "B", description: "B", referencePrice: try Price("100")),
            Stock(id: "A", company: "A", description: "A", referencePrice: try Price("100")),
            Stock(id: "C", company: "C", description: "C", referencePrice: try Price("200"))
        ]
        var quotes = stocks.map { StockQuote(stock: $0) }
        for direction in SortDirection.allCases {
            #expect(StockSort(metric: .change, direction: direction).sorted(quotes).map(\.id) == ["A", "B", "C"])
        }
        #expect(StockSort(metric: .price, direction: .ascending).sorted(quotes).map(\.id) == ["A", "B", "C"])
        #expect(StockSort(metric: .price, direction: .descending).sorted(quotes).map(\.id) == ["C", "A", "B"])
        quotes[0].apply(price: try Price("110"), at: .distantPast, sequence: 1)
        quotes[2].apply(price: try Price("180"), at: .distantPast, sequence: 2)
        #expect(StockSort(metric: .change, direction: .ascending).sorted(quotes).map(\.id) == ["C", "A", "B"])
        #expect(StockSort(metric: .change, direction: .descending).sorted(quotes).map(\.id) == ["B", "A", "C"])
        #expect(StockSort(metric: .price, direction: .ascending).sorted(quotes).map(\.id) == ["A", "B", "C"])
    }

    @Test func historyIsBoundedAndContainsReceivedUpdatesOnly() throws {
        var quote = StockQuote(stock: StockCatalog.stocks[0])
        #expect(quote.history.isEmpty)
        for sequence in 1...140 {
            quote.apply(price: try Price("100"), at: Date(timeIntervalSince1970: Double(sequence)), sequence: UInt64(sequence))
        }
        #expect(quote.history.count == 120)
        #expect(quote.history.first?.sequence == 21)
        #expect(quote.updatedAt == Date(timeIntervalSince1970: 140))
    }

    @Test func generatorIsDeterministicBoundedAndFair() throws {
        let quotes = StockCatalog.stocks.map { StockQuote(stock: $0) }
        var first = PriceGenerator(random: SeededRandomSource(seed: 42))
        var second = PriceGenerator(random: SeededRandomSource(seed: 42))
        var seen: Set<String> = []
        for _ in 0..<250 {
            let candidate = try first.next(in: quotes)
            #expect(candidate == (try second.next(in: quotes)))
            seen.insert(candidate.symbol)
            let original = try #require(quotes.first { $0.id == candidate.symbol })
            let difference = abs(candidate.price.value - original.price.value)
            #expect(difference <= original.price.value * Decimal(string: "0.008")! + Decimal(string: "0.01")!)
            #expect(candidate.price.value > 0)
        }
        #expect(seen.count == 25)
    }
}

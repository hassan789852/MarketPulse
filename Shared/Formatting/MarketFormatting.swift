import Foundation

enum MarketFormatting {
    static func price(_ value: Decimal, locale: Locale = .current) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(2)).locale(locale))
    }

    static func signedPrice(_ value: Decimal, locale: Locale = .current) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(2)).sign(strategy: .always(showZero: false)).locale(locale))
    }

    static func percent(_ ratio: Decimal, locale: Locale = .current) -> String {
        ratio.formatted(.percent.precision(.fractionLength(2)).sign(strategy: .always(includingZero: false)).locale(locale))
    }

    static func voiceOver(_ quote: StockQuote, locale: Locale = .current) -> String {
        let direction = quote.absoluteChange > 0 ? String(localized: "up") : quote.absoluteChange < 0 ? String(localized: "down") : String(localized: "unchanged")
        let movement = abs(quote.relativeChange).formatted(.percent.precision(.fractionLength(2)).locale(locale))
        return "\(quote.stock.company), \(quote.id), \(String(localized: "simulated price")) \(price(quote.price.value, locale: locale)), \(direction) \(movement)"
    }
}

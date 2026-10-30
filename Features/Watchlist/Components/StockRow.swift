import SwiftUI

struct StockRow: View {
    let model: QuoteModel
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: MarketTheme.compactGap) { identity; values }
            } else {
                HStack(spacing: MarketTheme.gap) { identity; Spacer(minLength: MarketTheme.compactGap); values }
            }
        }
        .padding(.vertical, MarketTheme.compactGap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MarketFormatting.voiceOver(model.quote))
        .accessibilityIdentifier("stock.\(model.id)")
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(model.id).font(.headline.weight(.bold)).foregroundStyle(.primary)
            Text(model.quote.stock.company)
                .font(.caption).foregroundStyle(.secondary)
                .lineLimit(2).multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var values: some View {
        VStack(alignment: typeSize.isAccessibilitySize ? .leading : .trailing, spacing: 5) {
            Text(MarketFormatting.price(model.quote.price.value))
                .font(.headline).monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1).minimumScaleFactor(0.8)
            HStack(spacing: MarketTheme.compactGap) {
                Image(systemName: MarketTheme.direction(model.quote.absoluteChange))
                Text(MarketFormatting.percent(model.quote.relativeChange))
                    .fixedSize(horizontal: true, vertical: false)
            }
            .font(.caption.weight(.semibold)).monospacedDigit()
            .foregroundStyle(MarketTheme.movement(model.quote.absoluteChange))
        }
        .fixedSize(horizontal: !typeSize.isAccessibilitySize, vertical: false)
    }
}

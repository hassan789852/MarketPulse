import SwiftUI
import Charts

struct PriceHistoryChart: View {
    let quote: StockQuote
    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: MarketTheme.gap) {
                HStack {
                    Text("Received history").font(.headline)
                    Spacer()
                    Text("\(quote.history.count) points").font(.caption).foregroundStyle(.secondary)
                }
                if quote.history.count >= 2 {
                    Chart(quote.history) { point in
                        LineMark(x: .value("Received", point.time), y: .value("Simulated USD", chartValue(point.price)))
                            .foregroundStyle(MarketTheme.accent)
                            .interpolationMethod(.linear)
                        PointMark(x: .value("Received", point.time), y: .value("Simulated USD", chartValue(point.price)))
                            .foregroundStyle(MarketTheme.accent)
                            .symbolSize(14)
                    }
                    .chartYScale(domain: chartDomain)
                    .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) }
                    .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
                    .frame(height: MarketTheme.chartHeight)
                    .accessibilityLabel("Simulated received price history")
                    .accessibilityValue("\(quote.history.count) received prices. Current price \(MarketFormatting.price(quote.price.value)).")
                } else {
                    VStack(spacing: MarketTheme.compactGap) {
                        Image(systemName: "waveform.path").font(.largeTitle).foregroundStyle(MarketTheme.accent)
                        Text(quote.history.isEmpty ? "Waiting for the first echo" : "One echo received")
                            .font(.subheadline.weight(.medium))
                        Text("The chart appears after two validated updates for this symbol.")
                            .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: MarketTheme.chartHeight)
                }
                Text("Simulated data · Up to 120 received updates · No historical market data")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
    /// Double is used only at the chart rendering boundary, never as authoritative money.
    private func chartValue(_ price: Price) -> Double { NSDecimalNumber(decimal: price.value).doubleValue }
    private var chartDomain: ClosedRange<Double> {
        let values = quote.history.map { chartValue($0.price) }
        let low = values.min() ?? chartValue(quote.price)
        let high = values.max() ?? low
        let padding = max((high - low) * 0.2, 0.02)
        return max(0, low - padding)...(high + padding)
    }
}

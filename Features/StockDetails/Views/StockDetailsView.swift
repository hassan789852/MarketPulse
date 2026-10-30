import SwiftUI

struct StockDetailsView: View {
    let model: QuoteModel
    let store: MarketStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MarketTheme.gap) {
                quoteHeader
                Panel { FeedControls(store: store, compact: true) }
                PriceHistoryChart(quote: model.quote)
                Panel {
                    VStack(alignment: .leading, spacing: MarketTheme.gap) {
                        Label("About the company", systemImage: "building.2").font(.headline)
                        Text(model.quote.stock.description)
                            .font(.body).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Divider()
                        referenceDetails
                    }
                }
                Label("All prices are simulated. Reference values are fictional and changes are measured from those values, not a market opening price.", systemImage: "info.circle")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, MarketTheme.compactGap)
                    .accessibilityIdentifier("details.disclosure")
            }
            .frame(maxWidth: MarketTheme.detailMaxWidth)
            .padding(MarketTheme.inset)
            .frame(maxWidth: .infinity)
        }
        .background(MarketTheme.background)
        .navigationTitle(model.id)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("details")
    }

    private var quoteHeader: some View {
        Panel {
            VStack(alignment: .leading, spacing: MarketTheme.gap) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: MarketTheme.compactGap) {
                        Text(model.id).font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(MarketTheme.accent)
                            .accessibilityIdentifier("details.ticker")
                        Text(model.quote.stock.company).font(.title2.weight(.bold))
                            .accessibilityIdentifier("details.company")
                    }
                    Spacer(minLength: MarketTheme.compactGap)
                    Text("DEMO").font(.caption2.weight(.bold))
                        .padding(MarketTheme.compactGap)
                        .background(MarketTheme.accent.opacity(0.10), in: Capsule())
                        .foregroundStyle(MarketTheme.accent)
                }
                Text("Current simulated price · USD").font(.caption).foregroundStyle(.secondary)
                Text(MarketFormatting.price(model.quote.price.value))
                    .font(.largeTitle.weight(.bold)).monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: model.quote.price)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .accessibilityIdentifier("details.price")
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: MarketTheme.compactGap) { movement; Text("from reference").font(.caption).foregroundStyle(.secondary) }
                    VStack(alignment: .leading, spacing: MarketTheme.compactGap) { movement; Text("from reference").font(.caption).foregroundStyle(.secondary) }
                }
                Divider()
                HStack(alignment: .top) {
                    Image(systemName: "clock").foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        if let date = model.quote.updatedAt {
                            Text("Last received \(date.formatted(date: .abbreviated, time: .standard))")
                        } else {
                            Text("Reference price · No update received yet")
                        }
                        if store.state != .connected {
                            Text("Feed \(store.state.title.lowercased()) · Prices retained")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption)
                }
            }
        }
    }

    private var movement: some View {
        Label {
            Text("\(MarketFormatting.signedPrice(model.quote.absoluteChange))  (\(MarketFormatting.percent(model.quote.relativeChange)))")
                .monospacedDigit()
        } icon: {
            Image(systemName: MarketTheme.direction(model.quote.absoluteChange))
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(MarketTheme.movement(model.quote.absoluteChange))
        .accessibilityIdentifier("details.change")
    }

    private var referenceDetails: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                metric("Reference price", value: MarketFormatting.price(model.quote.stock.referencePrice.value))
                Spacer()
                metric("Quote currency", value: "USD")
                Spacer()
                metric("Data source", value: "Postman echo")
            }
            VStack(alignment: .leading, spacing: MarketTheme.gap) {
                metric("Reference price", value: MarketFormatting.price(model.quote.stock.referencePrice.value))
                metric("Quote currency", value: "USD")
                metric("Data source", value: "Postman echo")
            }
        }
    }
    private func metric(_ label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold)).monospacedDigit()
        }
    }
}

import SwiftUI

struct WatchlistView: View {
    @Bindable var store: MarketStore
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        List(selection: $store.selection) {
            Section {
                FeedControls(store: store)
            }
            .listRowBackground(MarketTheme.surface)

            Section {
                SortControls(store: store)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
            }

            Section {
                if store.rows.isEmpty {
                    ContentUnavailableView("No symbols", systemImage: "chart.line.uptrend.xyaxis", description: Text("There are no stocks in this catalog."))
                }
                ForEach(store.sortedRows) { row in
                    NavigationLink(value: row.id) { StockRow(model: row) }
                        .listRowBackground(MarketTheme.surface)
                }
            } header: {
                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: MarketTheme.microGap))
                    : AnyLayout(HStackLayout())
                layout {
                    Text("Watchlist")
                    if !typeSize.isAccessibilitySize { Spacer() }
                    Text("\(store.rows.count) symbols · USD")
                        .accessibilityIdentifier("watchlist.count")
                }
                .font(.caption.weight(.semibold))
                .textCase(nil)
            } footer: {
                VStack(alignment: .leading, spacing: MarketTheme.compactGap) {
                    Text("Fictional prices. Real WebSocket.\nFor demonstration only — not market quotations or investment advice.")
                    if let time = store.lastReceivedAt {
                        Text("Last echo \(time.formatted(date: .omitted, time: .standard)) · \(store.receivedCount) received")
                            .accessibilityIdentifier("feed.received")
                    } else {
                        Text("Reference prices · No echoes received")
                            .accessibilityIdentifier("feed.received")
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
                .padding(.vertical, MarketTheme.compactGap)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(MarketTheme.background)
        .navigationTitle("MarketPulse")
        .accessibilityIdentifier("watchlist")
    }
}

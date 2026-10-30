import SwiftUI

struct SortControls: View {
    @Bindable var store: MarketStore
    var body: some View {
        HStack(spacing: MarketTheme.compactGap) {
            Picker("Sort by", selection: $store.sort.metric) {
                Text("Price").tag(SortMetric.price)
                Text("Price change").tag(SortMetric.change)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("sort.metric")
            Button {
                store.sort.direction = store.sort.direction == .ascending ? .descending : .ascending
            } label: {
                Image(systemName: store.sort.direction == .ascending ? "arrow.up" : "arrow.down")
                    .font(.body.weight(.semibold))
                    .frame(minWidth: MarketTheme.controlHeight, minHeight: MarketTheme.controlHeight)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Sort direction")
            .accessibilityValue(store.sort.direction == .ascending ? "Ascending" : "Descending")
            .accessibilityHint("Double tap to reverse the order")
            .accessibilityIdentifier("sort.direction")
        }
    }
}

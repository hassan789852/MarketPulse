import SwiftUI

@main
struct MarketPulseApp: App {
    @State private var store = AppContainer.makeStore()
    var body: some Scene {
        WindowGroup { MarketRootView(store: store) }
    }
}

struct MarketRootView: View {
    @Bindable var store: MarketStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var widthClass
    @State private var visibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            WatchlistView(store: store)
                .navigationSplitViewColumnWidth(min: 320, ideal: 370, max: 440)
        } detail: {
            if let symbol = store.selection, let model = store.row(for: symbol) {
                StockDetailsView(model: model, store: store)
            } else {
                ContentUnavailableView("Choose a symbol", systemImage: "chart.line.uptrend.xyaxis", description: Text("Select a company to explore its simulated price and received updates."))
                    .background(MarketTheme.background)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(MarketTheme.accent)
        .task { await store.observe() }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .inactive else { return }
            Task { await store.setForeground(phase == .active) }
        }
        .onChange(of: widthClass, initial: true) { _, width in
            if width == .regular, store.selection == nil { store.selection = store.rows.first?.id }
        }
    }
}

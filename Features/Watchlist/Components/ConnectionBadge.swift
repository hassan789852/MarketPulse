import SwiftUI

extension FeedState {
    var title: String {
        switch self {
        case .stopped: String(localized: "Stopped")
        case .connecting: String(localized: "Connecting")
        case .connected: String(localized: "Connected")
        case .reconnecting: String(localized: "Reconnecting")
        case .paused: String(localized: "Paused")
        case .failed: String(localized: "Disconnected")
        }
    }
    var symbol: String {
        switch self {
        case .connected: "checkmark.circle.fill"
        case .connecting, .reconnecting: "arrow.triangle.2.circlepath"
        case .stopped: "pause.circle.fill"
        case .paused: "moon.fill"
        case .failed: "wifi.slash"
        }
    }
    var help: String {
        switch self {
        case .stopped: String(localized: "Start the feed to receive simulated updates through a real WebSocket.")
        case .connecting: String(localized: "Waiting for the WebSocket handshake. Reference prices stay visible.")
        case .connected: String(localized: "Prices update only after a validated server echo.")
        case .reconnecting(let attempt, _): String(localized: "Connection interrupted. Retry \(attempt) of 5. Last prices are retained.")
        case .paused: String(localized: "Feed paused in the background. Last received prices are retained.")
        case .failed: String(localized: "Unable to connect. Last prices are retained. Tap Retry to reconnect.")
        }
    }
}

struct ConnectionBadge: View {
    let state: FeedState
    var body: some View {
        Label(state.title, systemImage: state.symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(state == .connected ? MarketTheme.positive : .secondary)
            .padding(.horizontal, MarketTheme.compactGap + 2)
            .padding(.vertical, MarketTheme.compactGap)
            .background((state == .connected ? MarketTheme.positive : Color.secondary).opacity(0.10), in: Capsule())
            .accessibilityIdentifier("connection.status")
            .accessibilityLabel(Text("Connection status"))
            .accessibilityValue(state.title)
    }
}

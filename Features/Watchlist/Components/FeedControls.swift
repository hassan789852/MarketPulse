import SwiftUI

struct FeedControls: View {
    let store: MarketStore
    var compact = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: MarketTheme.gap) {
            ViewThatFits(in: .horizontal) {
                HStack { identity; Spacer(minLength: MarketTheme.compactGap); ConnectionBadge(state: store.state) }
                VStack(alignment: .leading, spacing: MarketTheme.compactGap) { identity; ConnectionBadge(state: store.state) }
            }
            controls
            if !compact {
                Text(store.state.help)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("feed.explanation")
            }
        }
    }

    private var controls: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: MarketTheme.compactGap))
            : AnyLayout(HStackLayout(spacing: MarketTheme.compactGap))
        return layout {
            Button {
                Task { await store.start() }
            } label: {
                Label(store.state == .failed ? "Retry" : "Start", systemImage: "play.fill")
                    .foregroundStyle(MarketTheme.onAccent)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: MarketTheme.controlHeight)
            }
            .buttonStyle(.borderedProminent)
            .tint(MarketTheme.accent)
            .disabled(store.wantsRunning)
            .accessibilityIdentifier("feed.start")

            Button {
                Task { await store.stop() }
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: MarketTheme.controlHeight)
            }
            .buttonStyle(.bordered)
            .tint(.primary)
            .disabled(!store.wantsRunning)
            .accessibilityIdentifier("feed.stop")
        }
        .labelStyle(CenteredFeedLabelStyle())
        .font(.subheadline.weight(.semibold))
        .controlSize(.small)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: MarketTheme.microGap) {
            Text("SIMULATED MARKET FEED")
                .font(.caption2.weight(.bold)).tracking(1)
                .foregroundStyle(MarketTheme.accent)
            Text("Price feed").font(.headline)
        }
    }
}

/// Equal symbol space on each side keeps the title at the button's center.
/// The hidden trailing copy affects layout only and is excluded from VoiceOver.
private struct CenteredFeedLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: MarketTheme.compactGap) {
            configuration.icon.accessibilityHidden(true)
            configuration.title
            configuration.icon.hidden().accessibilityHidden(true)
        }
    }
}

import SwiftUI

/// Shared adaptive palette and layout tokens. All feature views use these semantic values.
enum MarketTheme {
    static let background = Color("Canvas")
    static let surface = Color("Surface")
    static let accent = Color("AccentColor")
    static let onAccent = Color("OnAccent")
    static let positive = Color("Positive")
    static let negative = Color("Negative")
    static let line = Color.primary.opacity(0.09)
    static let radius: CGFloat = 20
    static let smallRadius: CGFloat = 12
    static let gap: CGFloat = 16
    static let inset: CGFloat = 20
    static let microGap: CGFloat = 4
    static let compactGap: CGFloat = 8
    static let wideGap: CGFloat = 28
    static let controlHeight: CGFloat = 46
    static let detailMaxWidth: CGFloat = 820
    static let chartHeight: CGFloat = 190

    static func movement(_ value: Decimal) -> Color {
        value > 0 ? positive : value < 0 ? negative : .secondary
    }
    static func direction(_ value: Decimal) -> String {
        value > 0 ? "arrow.up.right" : value < 0 ? "arrow.down.right" : "minus"
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(MarketTheme.inset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MarketTheme.surface, in: RoundedRectangle(cornerRadius: MarketTheme.radius))
            .overlay { RoundedRectangle(cornerRadius: MarketTheme.radius).strokeBorder(MarketTheme.line) }
    }
}

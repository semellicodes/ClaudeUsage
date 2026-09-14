import SwiftUI

/// Superfície comum aos dois tamanhos, recortada pelo container do WidgetKit.
struct WidgetBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ContainerRelativeShape()
            .fill(.ultraThinMaterial)
            .overlay {
                ContainerRelativeShape()
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color(white: 0.20), Color(white: 0.10)]
                                : [Color(white: 0.99), Color(white: 0.90)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.80)
                        .shadow(.inner(color: .black.opacity(0.10), radius: 3, y: -2))
                    )
            }
            .overlay {
                ContainerRelativeShape()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .primary.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.75
                    )
            }
    }
}

import SwiftUI

/// Superfície comum aos dois tamanhos, recortada pelo container do WidgetKit.
struct WidgetBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ContainerRelativeShape()
            .fill(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(white: 0.20), Color(white: 0.10)]
                        : [Color(white: 0.99), Color(white: 0.90)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                ContainerRelativeShape()
                    .strokeBorder(Color.primary.opacity(0.16), lineWidth: 1)
            }
    }
}

import SwiftUI

struct WidgetHeaderView: View {

    let modelDisplayName: String?
    let spacing: CGFloat

    var body: some View {

        HStack(spacing: spacing) {

            Image(systemName: "sparkle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Claude Code")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: spacing)

            if let modelDisplayName {

                Text(modelDisplayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .fixedSize(
            horizontal: false,
            vertical: true
        )
    }
}


#if DEBUG

#Preview {

    WidgetHeaderView(
        modelDisplayName: "Sonnet 5",
        spacing: 6
    )
    .frame(width: 320)
    .padding()
    .background(Color.black)
}

#endif

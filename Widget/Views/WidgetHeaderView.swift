import SwiftUI

struct WidgetHeaderView: View {

    let modelDisplayName: String?
    var capturedAt: Date? = nil
    let spacing: CGFloat

    var body: some View {

        HStack(spacing: spacing) {

            Image(systemName: "sparkle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Claude")
                .font(.headline.weight(.bold))
                .lineLimit(1)

            Spacer(minLength: spacing)

            VStack(alignment: .trailing, spacing: 1) {
                if let modelDisplayName {
                    Text(modelDisplayName)
                        .font(.caption)
                }
                if let capturedAt {
                    Text(capturedAt, format: .dateTime.day().month().hour().minute())
                        .font(.system(size: 8))
                }
            }
            .foregroundStyle(.secondary)
            .lineLimit(1)

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

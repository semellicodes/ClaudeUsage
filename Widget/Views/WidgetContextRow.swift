import SwiftUI

struct WidgetContextRow: View {

    let usedPercentage: Double
    let spacing: CGFloat
    let padding: EdgeInsets

    private var normalizedPercentage: Double {
        min(
            max(usedPercentage, 0),
            100
        )
    }

    var body: some View {

        HStack(spacing: spacing) {

            Image(systemName: "doc.text")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("Contexto")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            ProgressView(
                value: normalizedPercentage,
                total: 100
            )
            .progressViewStyle(.linear)
            .tint(
                usageColor(
                    for: normalizedPercentage
                )
            )
            .frame(maxWidth: .infinity)
            .layoutPriority(1)

            Text(
                "\(Int(normalizedPercentage.rounded()))%"
            )
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(padding)
        .background {

            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .fill(
                Color.primary.opacity(0.06)
            )
        }
    }
}


#if DEBUG

#Preview {

    WidgetContextRow(
        usedPercentage: 22,
        spacing: 7,
        padding: EdgeInsets(
            top: 5,
            leading: 6,
            bottom: 5,
            trailing: 6
        )
    )
    .frame(width: 320)
    .padding()
    .background(Color.black)
}

#endif

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
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Contexto")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()

            ContextGradientBar(percentage: normalizedPercentage)
                .frame(maxWidth: .infinity)

            Text(
                "\(Int(normalizedPercentage.rounded()))%"
            )
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .fixedSize()
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
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            }
        }
    }
}


/// Barra do contexto com gradiente verde -> azul sobre uma trilha neutra. Ao contrário
/// dos gauges de SESSÃO/SEMANAL, essa cor não é semântica de alerta — só
/// marca a posição na faixa 0...100%, por isso não usa `usageColor`.
private struct ContextGradientBar: View {

    let percentage: Double

    private let barHeight: CGFloat = 7

    private static let gradient = LinearGradient(
        colors: [.green, .cyan],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {

        GeometryReader { geo in

            ZStack(alignment: .leading) {

                Capsule()
                    .fill(Color.primary.opacity(0.12))

                Capsule()
                    .fill(Self.gradient)
                    .frame(width: geo.size.width * percentage / 100)
            }
        }
        .frame(height: barHeight)
        .clipShape(Capsule())
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

import SwiftUI
import ClaudeUsageCore

struct UsageColumnsRow: View {

    let snapshot: UsageSnapshot
    let referenceDate: Date
    let columnSpacing: CGFloat
    let gaugeDiameter: CGFloat
    let labelSpacing: CGFloat
    let resetAdditionalSpacing: CGFloat
    let gaugeTextSize: CGFloat
    let dividerHeight: CGFloat
    let columnHeight: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: columnSpacing) {
            UsageColumnView(
                title: "SESSÃO · 5H", rateLimit: snapshot.fiveHour,
                referenceDate: referenceDate, remainingUnit: .hours,
                gaugeDiameter: gaugeDiameter, labelSpacing: labelSpacing, resetAdditionalSpacing: resetAdditionalSpacing, gaugeTextSize: gaugeTextSize
            )
            .frame(height: columnHeight, alignment: .top)
            Rectangle()
                .fill(Color.primary.opacity(0.05))
                .frame(width: 1, height: dividerHeight)
            UsageColumnView(
                title: "SEMANAL · 7D", rateLimit: snapshot.sevenDay,
                referenceDate: referenceDate, remainingUnit: .days,
                gaugeDiameter: gaugeDiameter, labelSpacing: labelSpacing, resetAdditionalSpacing: resetAdditionalSpacing, gaugeTextSize: gaugeTextSize
            )
            .frame(height: columnHeight, alignment: .top)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}


struct UsageColumnView: View {

    let title: String
    let rateLimit: RateLimit?
    let referenceDate: Date
    let remainingUnit: RemainingUnit
    let gaugeDiameter: CGFloat
    let labelSpacing: CGFloat
    let resetAdditionalSpacing: CGFloat
    let gaugeTextSize: CGFloat

    private var usedText: String {
        rateLimit.map { "\(displayedPercentages(for: $0).used)%" } ?? "—"
    }

    var body: some View {

        VStack(
            alignment: .center,
            spacing: labelSpacing
        ) {

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .opacity(0.85)
                .tracking(0.6)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            if let rateLimit, !rateLimit.hasReset(at: referenceDate) {

                PercentageRing(
                    percentage: rateLimit.usedPercentage,
                    diameter: gaugeDiameter,
                    color: usageColor(
                        for: rateLimit.usedPercentage
                    ),
                    valueText: usedText,
                    valueFont: .system(
                        size: gaugeTextSize,
                        weight: .bold,
                        design: .rounded
                    ),
                    strokeRatio: 0.105
                )

                Group {
                    if let reset = rateLimit.resetsAt {
                        ResetCountdownView(referenceDate: referenceDate, resetsAt: reset, unit: remainingUnit)
                    } else {
                        Text("Reinício não informado")
                    }
                }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(0.85)
                    .padding(.top, resetAdditionalSpacing)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

            } else {

                Label(
                    rateLimit == nil ? "Não informado" : "Janela reiniciada",
                    systemImage: rateLimit == nil ? "minus.circle" : "clock.badge.checkmark"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: gaugeDiameter)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .top
        )
    }
}

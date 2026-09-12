import SwiftUI
import ClaudeUsageCore

struct UsageColumnsRow: View {

    let snapshot: UsageSnapshot
    let referenceDate: Date
    let columnSpacing: CGFloat
    let gaugeDiameter: CGFloat
    let labelSpacing: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: columnSpacing) {
            UsageColumnView(
                title: "SESSÃO · 5H", rateLimit: snapshot.fiveHour,
                referenceDate: referenceDate, remainingUnit: .hours,
                gaugeDiameter: gaugeDiameter, labelSpacing: labelSpacing
            )
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 1, height: gaugeDiameter)
                .frame(maxHeight: .infinity)
            UsageColumnView(
                title: "SEMANAL · 7D", rateLimit: snapshot.sevenDay,
                referenceDate: referenceDate, remainingUnit: .days,
                gaugeDiameter: gaugeDiameter, labelSpacing: labelSpacing
            )
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

    private var usedText: String {
        rateLimit.map { "\(displayedPercentages(for: $0).used)%" } ?? "—"
    }

    var body: some View {

        VStack(
            alignment: .center,
            spacing: labelSpacing
        ) {

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
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
                        size: 20,
                        weight: .bold,
                        design: .rounded
                    )
                )

                Group {
                    if let reset = rateLimit.resetsAt {
                        HStack(spacing: 3) {
                            Text("reset em")
                            if remainingUnit == .hours {
                                Text(timerInterval: referenceDate...reset, countsDown: true)
                                    .monospacedDigit()
                                    .fixedSize()
                            } else {
                                Text(durationText(from: referenceDate, to: reset, unit: remainingUnit))
                            }
                        }
                    } else {
                        Text("Reinício não informado")
                    }
                }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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

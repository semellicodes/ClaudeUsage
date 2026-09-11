import SwiftUI
import ClaudeUsageCore

struct UsageColumnsRow: View {

    let snapshot: UsageSnapshot
    let referenceDate: Date
    let columnSpacing: CGFloat
    let gaugeDiameter: CGFloat
    let labelSpacing: CGFloat

    var body: some View {
        GeometryReader { geo in

            let rowHeight = gaugeDiameter + 38
            let columnWidth = geo.size.width * 0.44

            ZStack(alignment: .topLeading) {

                if let fiveHour = snapshot.fiveHour {
                    UsageColumnView(
                        title: "SESSÃO",
                        rateLimit: fiveHour,
                        referenceDate: referenceDate,
                        remainingUnit: .hours,
                        gaugeDiameter: gaugeDiameter,
                        labelSpacing: labelSpacing
                    )
                    .frame(
                        width: columnWidth,
                        height: rowHeight,
                        alignment: .top
                    )
                    .position(
                        x: geo.size.width * 0.25,
                        y: rowHeight / 2
                    )
                }

                if let sevenDay = snapshot.sevenDay {
                    UsageColumnView(
                        title: "SEMANAL",
                        rateLimit: sevenDay,
                        referenceDate: referenceDate,
                        remainingUnit: .days,
                        gaugeDiameter: gaugeDiameter,
                        labelSpacing: labelSpacing
                    )
                    .frame(
                        width: columnWidth,
                        height: rowHeight,
                        alignment: .top
                    )
                    .position(
                        x: geo.size.width * 0.75,
                        y: rowHeight / 2
                    )
                }
            }
            .frame(
                width: geo.size.width,
                height: rowHeight
            )
        }
        .frame(height: gaugeDiameter + 38)
    }
}


struct UsageColumnView: View {

    let title: String
    let rateLimit: RateLimit
    let referenceDate: Date
    let remainingUnit: RemainingUnit
    let gaugeDiameter: CGFloat
    let labelSpacing: CGFloat

    private var resetText: String {
        durationText(
            from: referenceDate,
            to: rateLimit.resetsAt,
            unit: remainingUnit
        )
    }

    private var usedText: String {
        "\(displayedPercentages(for: rateLimit).used)%"
    }

    var body: some View {

        VStack(
            alignment: .center,
            spacing: labelSpacing
        ) {

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            if rateLimit.resetsAt > referenceDate {

                PercentageRing(
                    percentage: rateLimit.usedPercentage,
                    diameter: gaugeDiameter,
                    color: usageColor(
                        for: rateLimit.usedPercentage
                    ),
                    valueText: usedText,
                    valueFont: .system(
                        size: 15,
                        weight: .bold,
                        design: .rounded
                    )
                )

                Text("reset em \(resetText)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

            } else {

                Label(
                    "Aguardando atualização",
                    systemImage: "clock.arrow.circlepath"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .top
        )
    }
}

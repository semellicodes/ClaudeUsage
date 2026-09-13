import SwiftUI
import WidgetKit
import ClaudeUsageCore

struct SmallWidgetView: View {

    let entry: UsageEntry

    var body: some View {

            let metrics = SmallWidgetMetrics(size: entry.displaySize)

            VStack(spacing: 0) {

                smallHeader

                Group {

                    if entry.snapshot != nil {
                        if let limit = entry.selectedRateLimit, !limit.hasReset(at: entry.date) {
                            sessionContent(
                                rateLimit: limit,
                                unit: entry.window == .fiveHour ? .hours : .days,
                                metrics: metrics
                            )
                        } else {
                            placeholder(
                                text: entry.selectedRateLimit == nil
                                    ? "Limite de \(entry.window == .fiveHour ? "5h" : "7d") não informado pela fonte"
                                    : "Janela reiniciada. Aguardando a próxima atualização.",
                                systemImage: entry.selectedRateLimit == nil ? "minus.circle" : "clock.badge.checkmark"
                            )
                        }
                    } else {
                        placeholder(text: entry.missingDataMessage, systemImage: nil)
                    }
                }
                .padding(
                    .top,
                    metrics.headerBottomSpacing
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                if let message = entry.syncMessage {
                    Text(message)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                } else if let capturedAt = entry.snapshot?.capturedAt {
                    Text(capturedAt, format: .dateTime.day().month().hour().minute())
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(metrics.padding)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        .containerBackground(for: .widget) {
            WidgetBackground()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }


    private var smallHeader: some View {

        HStack(alignment: .firstTextBaseline, spacing: 6) {

            Image(systemName: "sparkle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(entry.model.name ?? entry.snapshot?.modelDisplayName ?? "Claude")
                .font(.headline.weight(.bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(entry.window == .fiveHour ? "5h" : "7d")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }


    @ViewBuilder
    private func sessionContent(
        rateLimit: RateLimit,
        unit: RemainingUnit,
        metrics: SmallWidgetMetrics
    ) -> some View {

        let percentages = displayedPercentages(for: rateLimit)

        VStack(
            alignment: .center,
            spacing: metrics.verticalSpacing
        ) {

            PercentageRing(
                percentage: rateLimit.usedPercentage,
                diameter: metrics.gaugeDiameter,
                color: usageColor(for: rateLimit.usedPercentage),
                valueText: "\(percentages.used)%",
                valueFont: .system(
                    size: metrics.gaugeTextSize,
                    weight: .bold,
                    design: .rounded
                )
            )

            Text("\(percentages.remaining)% restante")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Group {
                if let reset = rateLimit.resetsAt {
                    ResetCountdownView(referenceDate: entry.date, resetsAt: reset, unit: unit)
                } else {
                    Text("Reinício não informado")
                }
            }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }


    private func placeholder(
        text: String,
        systemImage: String?
    ) -> some View {

        Group {

            if let systemImage {

                Label(
                    text,
                    systemImage: systemImage
                )

            } else {

                Text(text)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(
            horizontal: false,
            vertical: true
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }


    private var accessibilityLabel: String {

        guard entry.snapshot != nil else { return entry.missingDataMessage }
        let window = entry.window == .fiveHour ? "5 horas" : "7 dias"
        guard let limit = entry.selectedRateLimit else {
            return "ClaudeUsage: limite não informado de \(window)"
        }
        guard !limit.hasReset(at: entry.date) else {
            return "ClaudeUsage: janela reiniciada de \(window)"
        }
        return "ClaudeUsage: \(displayedPercentages(for: limit).used) por cento usado no limite de \(window)"
    }
}


// MARK: - Layout Metrics

private struct SmallWidgetMetrics {

    let padding: CGFloat
    let gaugeDiameter: CGFloat
    let gaugeTextSize: CGFloat
    let verticalSpacing: CGFloat
    let headerBottomSpacing: CGFloat

    init(size: CGSize) {

        let side = min(
            size.width,
            size.height
        )

        padding = side * 0.06
        verticalSpacing = 3
        headerBottomSpacing = 4
        let headerHeight: CGFloat = 16
        let captionHeight: CGFloat = 12
        let footerHeight: CGFloat = 12
        let reservedHeight = padding * 2 + headerHeight + captionHeight * 2
            + footerHeight + verticalSpacing * 2 + headerBottomSpacing
        gaugeDiameter = max(54, min((size.width - padding * 2) * 0.65,
            size.height - reservedHeight, 112))
        gaugeTextSize = gaugeDiameter * 0.30
    }
}


#if DEBUG

#Preview("Small", as: .systemSmall) {

    ClaudeUsageWidget()

} timeline: {

    let now = Date()

    UsageEntry(
        date: now,
        snapshot: UsageSnapshot(
            schemaVersion: UsageSnapshot.currentSchemaVersion,
            capturedAt: now,
            claudeCodeVersion: "2.0.1",
            sessionID: "preview-session",
            modelDisplayName: "Sonnet 5",

            fiveHour: RateLimit(
                usedPercentage: 89,
                resetsAt: now.addingTimeInterval(
                    1 * 3600 + 43 * 60
                )
            ),

            sevenDay: RateLimit(
                usedPercentage: 18,
                resetsAt: now.addingTimeInterval(
                    4 * 24 * 3600
                )
            ),

            context: ContextUsage(
                inputTokens: 44_000,
                outputTokens: 0,
                windowSize: 200_000,
                usedPercentage: 22,
                remainingPercentage: 78
            )
        )
    )
}

#endif

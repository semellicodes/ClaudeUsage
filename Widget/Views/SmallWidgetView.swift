import SwiftUI
import WidgetKit
import ClaudeUsageCore

struct SmallWidgetView: View {

    let entry: UsageEntry

    var body: some View {

        GeometryReader { geo in

            let metrics = SmallWidgetMetrics(size: geo.size)

            VStack(spacing: 0) {

                smallHeader

                Group {

                    if let snapshot = entry.snapshot {

                        if let fiveHour = snapshot.fiveHour,
                           fiveHour.resetsAt > entry.date {

                            sessionContent(
                                rateLimit: fiveHour,
                                unit: .hours,
                                metrics: metrics
                            )

                        } else if let sevenDay = snapshot.sevenDay,
                                  sevenDay.resetsAt > entry.date {

                            sessionContent(
                                rateLimit: sevenDay,
                                unit: .days,
                                metrics: metrics
                            )

                        } else {

                            placeholder(
                                text: "Limites ainda não disponíveis",
                                systemImage: "clock.arrow.circlepath"
                            )
                        }

                    } else {

                        placeholder(
                            text: "Abra o Claude Code e envie uma mensagem",
                            systemImage: nil
                        )
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
            }
            .padding(metrics.padding)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }
        .containerBackground(for: .widget) {
            Color(nsColor: .windowBackgroundColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }


    private var smallHeader: some View {

        HStack(spacing: 6) {

            Image(systemName: "sparkle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Claude")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 0)
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

        let resetText = durationText(
            from: entry.date,
            to: rateLimit.resetsAt,
            unit: unit
        )

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
                    .title2,
                    design: .rounded
                ).bold()
            )

            Text("\(percentages.remaining)% restante")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("reset em \(resetText)")
                .font(.caption2)
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

        guard let snapshot = entry.snapshot else {
            return "ClaudeUsage: sem dados carregados ainda"
        }

        if let fiveHour = snapshot.fiveHour,
           fiveHour.resetsAt > entry.date {

            return "ClaudeUsage: \(Int(fiveHour.usedPercentage)) por cento usado no limite de 5 horas"
        }

        if let sevenDay = snapshot.sevenDay,
           sevenDay.resetsAt > entry.date {

            return "ClaudeUsage: \(Int(sevenDay.usedPercentage)) por cento usado no limite de 7 dias"
        }

        return "ClaudeUsage: limites ainda não disponíveis"
    }
}


// MARK: - Layout Metrics

private struct SmallWidgetMetrics {

    let padding: CGFloat
    let gaugeDiameter: CGFloat
    let verticalSpacing: CGFloat
    let headerBottomSpacing: CGFloat

    init(size: CGSize) {

        let side = min(
            size.width,
            size.height
        )

        padding = side * 0.085

        gaugeDiameter = min(
            max(
                side * 0.42,
                52
            ),
            78
        )

        verticalSpacing = side * 0.035

        headerBottomSpacing = side * 0.045
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

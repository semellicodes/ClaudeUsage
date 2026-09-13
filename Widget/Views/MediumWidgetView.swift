import SwiftUI
import WidgetKit
import ClaudeUsageCore

struct MediumWidgetView: View {

    let entry: UsageEntry

    var body: some View {
            let metrics = MediumWidgetMetrics(size: entry.displaySize,
                showsContext: entry.snapshot?.context?.usedPercentage != nil,
                showsModel: (entry.snapshot?.modelDisplayName ?? entry.model.name) != nil)

            VStack(spacing: 0) {

                // Cabeçalho
                WidgetHeaderView(
                    modelDisplayName: entry.snapshot?.modelDisplayName ?? entry.model.name,
                    capturedAt: entry.snapshot?.capturedAt,
                    spacing: metrics.headerItemSpacing
                )

                if let snapshot = entry.snapshot {

                    UsageColumnsRow(
                        snapshot: snapshot,
                        referenceDate: entry.date,
                        columnSpacing: metrics.columnSpacing,
                        gaugeDiameter: metrics.gaugeDiameter,
                        labelSpacing: metrics.labelGaugeSpacing,
                        gaugeTextSize: metrics.gaugeTextSize,
                        dividerHeight: metrics.dividerHeight,
                        columnHeight: metrics.columnHeight
                    )
                    .padding(.top, metrics.headerBottomSpacing)
                    .frame(maxHeight: .infinity)

                    // Contexto independe da disponibilidade dos limites.
                    if let context = snapshot.context,
                       let used = context.usedPercentage {

                        WidgetContextRow(
                            usedPercentage: used,
                            spacing: metrics.contextRowSpacing,
                            padding: metrics.contextRowPadding
                        )
                        .padding(
                            .top,
                            metrics.columnsBottomSpacing
                        )
                    }

                } else {

                    placeholder(
                        text: entry.missingDataMessage,
                        systemImage: nil
                    )
                    .padding(.top, metrics.headerBottomSpacing)
                }
            }
            .padding(
                .horizontal,
                metrics.horizontalPadding
            )
            .padding(
                .vertical,
                metrics.verticalPadding
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        .containerBackground(for: .widget) {
            WidgetBackground()
        }
        .overlay(alignment: .bottom) {
            if let message = entry.syncMessage {
                Text(message)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.orange)
                    .lineLimit(1)
                    .padding(.bottom, 5)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            accessibilityLabel(for: entry.snapshot)
        )
    }


    // MARK: - Placeholder

    private func placeholder(
        text: String,
        systemImage: String?
    ) -> some View {

        VStack {
            Spacer(minLength: 0)

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
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }


    // MARK: - Accessibility

    private func accessibilityLabel(
        for snapshot: UsageSnapshot?
    ) -> String {

        guard let snapshot else {
            return "ClaudeUsage: sem dados carregados ainda"
        }

        var parts: [String] = []

        if let fiveHour = snapshot.fiveHour,
           !fiveHour.hasReset(at: entry.date) {

            parts.append(
                "\(Int(fiveHour.usedPercentage)) por cento usado na sessão"
            )
        }

        if let sevenDay = snapshot.sevenDay,
           !sevenDay.hasReset(at: entry.date) {

            parts.append(
                "\(Int(sevenDay.usedPercentage)) por cento usado no limite semanal"
            )
        }

        if let context = snapshot.context,
           let used = context.usedPercentage {

            parts.append(
                "\(Int(used)) por cento de contexto usado"
            )
        }

        if parts.isEmpty {
            return "ClaudeUsage: limites ainda não disponíveis"
        }

        return "ClaudeUsage: " + parts.joined(separator: ", ")
    }
}


// MARK: - Layout

private struct MediumWidgetMetrics {

    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    let headerItemSpacing: CGFloat
    let headerBottomSpacing: CGFloat

    let columnSpacing: CGFloat
    let labelGaugeSpacing: CGFloat
    let gaugeDiameter: CGFloat
    let gaugeTextSize: CGFloat
    let dividerHeight: CGFloat
    let columnHeight: CGFloat

    let columnsBottomSpacing: CGFloat

    let contextRowSpacing: CGFloat
    let contextRowPadding: EdgeInsets

    init(size: CGSize, showsContext: Bool, showsModel: Bool) {

        // Margens externas
        horizontalPadding = 18
        verticalPadding = 11

        // Cabeçalho
        headerItemSpacing = 6
        headerBottomSpacing = 5

        // Distância entre Sessão e Semanal
        columnSpacing = 12

        // Título -> círculo -> reset
        labelGaugeSpacing = 3

        let headerHeight: CGFloat = showsModel ? 25 : 16
        let captionHeight: CGFloat = 12
        let contextHeight: CGFloat = showsContext ? 28 : 0
        let columnWidth = (size.width - horizontalPadding * 2 - columnSpacing * 2 - 1) / 2
        let reservedHeight = verticalPadding * 2 + headerHeight + headerBottomSpacing
            + captionHeight * 2 + labelGaugeSpacing * 2 + contextHeight
        gaugeDiameter = max(32, min(columnWidth * 0.70, size.height - reservedHeight, 104))
        gaugeTextSize = gaugeDiameter * 0.30
        dividerHeight = gaugeDiameter + captionHeight + labelGaugeSpacing
        columnHeight = gaugeDiameter + (captionHeight + labelGaugeSpacing) * 2

        // Distância até Contexto
        columnsBottomSpacing = 4

        // Linha de contexto
        contextRowSpacing = 7

        contextRowPadding = EdgeInsets(
            top: 5,
            leading: 8,
            bottom: 5,
            trailing: 8
        )
    }
}

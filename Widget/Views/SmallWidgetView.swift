import SwiftUI
import ClaudeUsageCore

struct SmallWidgetView: View {
    let entry: UsageEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Claude", systemImage: "gauge.medium")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Spacer(minLength: 2)

            if let snapshot = entry.snapshot {
                if let fiveHour = snapshot.fiveHour, fiveHour.resetsAt > entry.date {
                    usageGauge(percentage: fiveHour.usedPercentage, caption: "5 horas")
                } else if let sevenDay = snapshot.sevenDay, sevenDay.resetsAt > entry.date {
                    usageGauge(percentage: sevenDay.usedPercentage, caption: "7 dias")
                } else {
                    Text("Limites ainda não disponíveis")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Abra o Claude Code e envie uma mensagem")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color(nsColor: .windowBackgroundColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func usageGauge(percentage: Double, caption: String) -> some View {
        Gauge(value: percentage, in: 0...100) {
            EmptyView()
        } currentValueLabel: {
            Text("\(Int(percentage))%")
                .font(.title2.bold())
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(usageColor(for: percentage))

        Text(caption)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private var accessibilityLabel: String {
        guard let snapshot = entry.snapshot else {
            return "ClaudeUsage: sem dados carregados ainda"
        }
        if let fiveHour = snapshot.fiveHour, fiveHour.resetsAt > entry.date {
            return "ClaudeUsage: \(Int(fiveHour.usedPercentage)) por cento usado no limite de 5 horas"
        }
        if let sevenDay = snapshot.sevenDay, sevenDay.resetsAt > entry.date {
            return "ClaudeUsage: \(Int(sevenDay.usedPercentage)) por cento usado no limite de 7 dias"
        }
        return "ClaudeUsage: limites ainda não disponíveis"
    }
}

func usageColor(for percentage: Double) -> Color {
    switch percentage {
    case ..<70: .green
    case ..<90: .orange
    default: .red
    }
}

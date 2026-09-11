import SwiftUI
import WidgetKit
import ClaudeUsageCore

struct MediumWidgetView: View {
    let entry: UsageEntry

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let snapshot = entry.snapshot {
                content(for: snapshot)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Claude", systemImage: "gauge.medium")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text("Abra o Claude Code e envie uma mensagem para carregar o uso")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color(nsColor: .windowBackgroundColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: entry.snapshot))
    }

    @ViewBuilder
    private func content(for snapshot: UsageSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(snapshot.modelDisplayName ?? "Claude", systemImage: "gauge.medium")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            if snapshot.fiveHour == nil && snapshot.sevenDay == nil {
                Label("Limites ainda não disponíveis", systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let context = snapshot.context, let used = context.usedPercentage {
                Label("Contexto: \(Int(used))% usado", systemImage: "doc.text")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if let fiveHour = snapshot.fiveHour {
            RateLimitColumn(title: "5 horas", rateLimit: fiveHour, referenceDate: entry.date)
        }
        if let sevenDay = snapshot.sevenDay {
            RateLimitColumn(title: "7 dias", rateLimit: sevenDay, referenceDate: entry.date)
        }
    }

    private func accessibilityLabel(for snapshot: UsageSnapshot?) -> String {
        guard let snapshot else {
            return "ClaudeUsage: sem dados carregados ainda"
        }
        var parts: [String] = []
        if let fiveHour = snapshot.fiveHour, fiveHour.resetsAt > entry.date {
            parts.append("\(Int(fiveHour.usedPercentage)) por cento usado no limite de 5 horas")
        }
        if let sevenDay = snapshot.sevenDay, sevenDay.resetsAt > entry.date {
            parts.append("\(Int(sevenDay.usedPercentage)) por cento usado no limite de 7 dias")
        }
        if parts.isEmpty {
            return "ClaudeUsage: limites ainda não disponíveis"
        }
        return "ClaudeUsage: " + parts.joined(separator: ", ")
    }
}

private struct RateLimitColumn: View {
    let title: String
    let rateLimit: RateLimit
    let referenceDate: Date

    var body: some View {
        VStack(spacing: 4) {
            if rateLimit.resetsAt > referenceDate {
                Gauge(value: rateLimit.usedPercentage, in: 0...100) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(Int(rateLimit.usedPercentage))%")
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(usageColor(for: rateLimit.usedPercentage))
                .widgetAccentable()
            } else {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

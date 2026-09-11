import SwiftUI
import ClaudeUsageCore

/// Conteúdo do dropdown do MenuBarExtra. Cada bloco (5h, 7d, contexto) renderiza
/// independentemente quando presente — perder uma janela não quebra o layout.
struct MenuBarView: View {
    let snapshot: UsageSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let snapshot {
                content(for: snapshot)
            } else {
                Text("Abra o Claude Code e envie uma mensagem para carregar o uso")
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(minWidth: 260, alignment: .leading)
    }

    @ViewBuilder
    private func content(for snapshot: UsageSnapshot) -> some View {
        if let model = snapshot.modelDisplayName {
            Text(model)
                .font(.headline)
        }

        if snapshot.fiveHour == nil && snapshot.sevenDay == nil {
            Text("Limites ainda não disponíveis")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            if let fiveHour = snapshot.fiveHour {
                RateLimitRow(title: "5 horas", rateLimit: fiveHour)
            }
            if let sevenDay = snapshot.sevenDay {
                RateLimitRow(title: "7 dias", rateLimit: sevenDay)
            }
        }

        if let context = snapshot.context {
            Divider()
            ContextRow(context: context)
        }

        Divider()
        Text("Atualizado às \(snapshot.capturedAt.formatted(date: .omitted, time: .shortened))")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}

private struct RateLimitRow: View {
    let title: String
    let rateLimit: RateLimit

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.bold())
            if rateLimit.resetsAt <= Date() {
                Text("Aguardando atualização após o reset")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(Int(rateLimit.usedPercentage))% usado · \(Int(rateLimit.remainingPercentage))% restante")
                    .font(.caption)
                Text("Reinicia \(rateLimit.resetsAt.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ContextRow: View {
    let context: ContextUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Contexto")
                .font(.subheadline.bold())
            if let used = context.usedPercentage {
                Text("\(Int(used))% usado")
                    .font(.caption)
            } else {
                Text("Percentual de contexto indisponível")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Label compacto na barra de menus. Curto, e nunca chama rate-limit de "tokens".
struct MenuBarLabel: View {
    let snapshot: UsageSnapshot?

    var body: some View {
        if let fiveHour = snapshot?.fiveHour, fiveHour.resetsAt > Date() {
            Label("\(Int(fiveHour.usedPercentage))%", systemImage: "gauge.medium")
        } else {
            Image(systemName: "gauge.medium")
        }
    }
}

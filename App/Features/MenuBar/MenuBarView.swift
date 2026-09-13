import SwiftUI
import ClaudeUsageCore

/// Conteúdo do dropdown do MenuBarExtra. Cada bloco (5h, 7d, contexto) renderiza
/// independentemente quando presente — perder uma janela não quebra o layout.
struct MenuBarView: View {
    let snapshot: UsageSnapshot?
    var referenceDate = Date()
    var storageError: String? = nil

    var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                if let snapshot {
                    content(for: snapshot, at: referenceDate)
                } else {
                    Text("Ative a sincronização da conta para carregar os limites de uso.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(snapshot?.source == .account
                     ? "Fonte: conta Claude · uso compartilhado entre Desktop e terminal."
                     : "Fonte desta leitura: statusLine do terminal.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let storageError {
                    Text(storageError).font(.caption).foregroundStyle(.red)
                }
            }
            .padding(14)
            .frame(minWidth: 280, maxWidth: 340, alignment: .leading)
    }

    @ViewBuilder
    private func content(for snapshot: UsageSnapshot, at date: Date) -> some View {
        if let model = snapshot.modelDisplayName {
            Text(model)
                .font(.headline)
        }

        RateLimitRow(title: "5 horas", rateLimit: snapshot.fiveHour, referenceDate: date)
        RateLimitRow(title: "7 dias", rateLimit: snapshot.sevenDay, referenceDate: date)
        if snapshot.fiveHour == nil || snapshot.sevenDay == nil {
            Text("Uma janela ausente não indica bloqueio. Aguarde uma nova leitura da fonte.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        if let context = snapshot.context {
            Divider()
            ContextRow(context: context)
        }

        Divider()
        Text("Atualizado às \(snapshot.capturedAt.formatted(date: .abbreviated, time: .shortened))")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}

private struct RateLimitRow: View {
    let title: String
    let rateLimit: RateLimit?
    let referenceDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.bold())
            if let rateLimit {
                if rateLimit.hasReset(at: referenceDate) {
                    Text("Janela reiniciada · próximo uso ainda não informado")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    let used = Int(rateLimit.usedPercentage.rounded())
                    Text("\(used)% usado · \(100 - used)% restante")
                        .font(.caption)
                    Group {
                        if let reset = rateLimit.resetsAt {
                            HStack(spacing: 3) {
                                Text("Reinicia em")
                                Text(timerInterval: referenceDate...reset, countsDown: true)
                                    .monospacedDigit()
                            }
                        } else {
                            Text("Data de reinício ainda não informada")
                        }
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                }
            } else {
                Text("Não informado pela fonte")
                    .font(.caption).foregroundStyle(.secondary)
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
    var referenceDate = Date()

    var body: some View {
            if let fiveHour = snapshot?.fiveHour, !fiveHour.hasReset(at: referenceDate) {
                Label("\(Int(fiveHour.usedPercentage.rounded()))%", systemImage: "gauge.medium")
            } else {
                Image(systemName: "gauge.medium")
            }
    }
}

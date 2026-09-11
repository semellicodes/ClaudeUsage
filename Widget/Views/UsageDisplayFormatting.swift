import SwiftUI
import ClaudeUsageCore

func usageColor(for percentage: Double) -> Color {
    switch percentage {
    case ..<70: .green
    case ..<90: .orange
    default: .red
    }
}

/// "Usado" arredondado para exibição, com "restante" derivado como o
/// complemento exato (100 - usado) — arredondar os dois separadamente pode
/// fazer a soma não bater em 100 (ex.: 56% + 43%).
func displayedPercentages(for rateLimit: RateLimit) -> (used: Int, remaining: Int) {
    let used = Int(rateLimit.usedPercentage.rounded())
    return (used, 100 - used)
}

enum RemainingUnit {
    case hours
    case days
}

/// Formato compacto "4h 27min" / "6d" — dígitos + abreviação de unidade, sem
/// depender de formatação relativa localizada (evita reintroduzir o bug de
/// idioma misto corrigido na etapa 7).
func durationText(from now: Date, to resetsAt: Date, unit: RemainingUnit) -> String {
    switch unit {
    case .hours:
        let comps = Calendar.current.dateComponents([.hour, .minute], from: now, to: resetsAt)
        let hours = max(comps.hour ?? 0, 0)
        let minutes = max(comps.minute ?? 0, 0)
        return "\(hours)h \(minutes)min"
    case .days:
        let days = max(Calendar.current.dateComponents([.day], from: now, to: resetsAt).day ?? 0, 0)
        return "\(days) dias"
    }
}

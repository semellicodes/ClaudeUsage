import SwiftUI

/// Mede um texto estático; o contador dinâmico não tem largura intrínseca confiável no WidgetKit.
struct ResetCountdownView: View {
    let referenceDate: Date
    let resetsAt: Date
    let unit: RemainingUnit

    var body: some View {
        HStack(spacing: 3) {
            Text("Reseta em")
            if unit == .hours {
                let hours = max(0, Int(resetsAt.timeIntervalSince(referenceDate) / 3600))
                Text("\(hours):00:00")
                    .hidden()
                    .overlay {
                        Text(timerInterval: referenceDate...resetsAt, countsDown: true)
                            .multilineTextAlignment(.center)
                    }
                    .monospacedDigit()
            } else {
                Text(durationText(from: referenceDate, to: resetsAt, unit: unit))
            }
        }
    }
}

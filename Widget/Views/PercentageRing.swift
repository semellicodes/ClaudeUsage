import SwiftUI

struct PercentageRing: View {

    let percentage: Double
    let diameter: CGFloat
    let color: Color
    let valueText: String
    let valueFont: Font

    private var normalizedPercentage: Double {
        min(
            max(percentage / 100, 0),
            1
        )
    }

    private var lineWidth: CGFloat {
        max(
            diameter * 0.12,
            2.5
        )
    }

    var body: some View {

        ZStack {

            Circle()
                .inset(by: lineWidth / 2)
                .stroke(
                    color.opacity(0.24),
                    lineWidth: lineWidth
                )

            Circle()
                .inset(by: lineWidth / 2)
                .trim(
                    from: 0,
                    to: normalizedPercentage
                )
                .stroke(
                    color.gradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(
                    .degrees(-90)
                )
                .widgetAccentable()

            Text(valueText)
                .font(valueFont)
                .monospacedDigit()
                .padding(.horizontal, lineWidth)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(
            width: diameter,
            height: diameter
        )
    }
}


#if DEBUG

#Preview {

    PercentageRing(
        percentage: 89,
        diameter: 70,
        color: .orange,
        valueText: "89%",
        valueFont:
            .system(
                .title2,
                design: .rounded
            )
            .bold()
    )
    .padding()
    .background(Color.black)
}

#endif

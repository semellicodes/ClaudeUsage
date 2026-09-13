import WidgetKit
import SwiftUI

struct ClaudeUsageWidget: Widget {

    let kind: String = "ClaudeUsageConfigurableWidget"

    var body: some WidgetConfiguration {

        AppIntentConfiguration(
            kind: kind,
            intent: WidgetSelectionIntent.self,
            provider: UsageTimelineProvider()
        ) { entry in

            ClaudeUsageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Claude Usage · Modelos")
        .description(
            "Acompanhe os limites de 5h/7d da conta Claude no Desktop e no terminal."
        )
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
        .contentMarginsDisabled()
    }
}

/// O identificador original precisa continuar aceitando pedidos sem intent.
struct LegacyClaudeUsageWidget: Widget {
    let kind = "ClaudeUsageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LegacyUsageTimelineProvider()) { entry in
            ClaudeUsageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Claude Usage")
        .description("Uso da conta Claude: limites de 5h e 7d, no Desktop e no terminal.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

private struct ClaudeUsageWidgetEntryView: View {

    @Environment(\.widgetFamily)
    private var family

    let entry: UsageEntry

    var body: some View {

        switch family {

        case .systemMedium:
            MediumWidgetView(entry: entry)

        default:
            SmallWidgetView(entry: entry)
        }
    }
}


@main
struct ClaudeUsageWidgetBundle: WidgetBundle {

    var body: some Widget {
        LegacyClaudeUsageWidget()
        ClaudeUsageWidget()
    }
}

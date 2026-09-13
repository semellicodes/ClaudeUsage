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
        .containerBackgroundRemovable(false)
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
        .containerBackgroundRemovable(false)
    }
}

private struct ClaudeUsageWidgetEntryView: View {

    @Environment(\.widgetFamily)
    private var family

    let entry: UsageEntry

    var body: some View {

        Group {
            switch family {
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .environment(\.locale, Locale(identifier: "pt_BR"))
    }
}


@main
struct ClaudeUsageWidgetBundle: WidgetBundle {

    var body: some Widget {
        LegacyClaudeUsageWidget()
        ClaudeUsageWidget()
    }
}

import WidgetKit
import SwiftUI

struct ClaudeUsageWidget: Widget {

    let kind: String = "ClaudeUsageWidget"

    var body: some WidgetConfiguration {

        AppIntentConfiguration(
            kind: kind,
            intent: WidgetSelectionIntent.self,
            provider: UsageTimelineProvider()
        ) { entry in

            ClaudeUsageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Claude Usage")
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
        ClaudeUsageWidget()
    }
}

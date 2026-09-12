import WidgetKit
import ClaudeUsageCore

struct UsageEntry: TimelineEntry {
    let date: Date
    let snapshot: UsageSnapshot?
    var model: WidgetModelSelection = .automatic
    var window: WidgetWindowSelection = .fiveHour

    var missingDataMessage: String {
        "Abra o ClaudeUsage e ative a sincronização da conta para carregar o uso"
    }

    var selectedRateLimit: RateLimit? {
        window == .fiveHour ? snapshot?.fiveHour : snapshot?.sevenDay
    }
}

/// Lê apenas snapshots sanitizados do App Group.
struct UsageTimelineProvider: AppIntentTimelineProvider {
    private static let appGroupIdentifier = "3U9MRVV4FR.claudeusage"

    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: Date(), snapshot: nil)
    }

    func snapshot(for configuration: WidgetSelectionIntent, in context: Context) async -> UsageEntry {
        entry(for: configuration, date: Date())
    }

    func timeline(for configuration: WidgetSelectionIntent, in context: Context) async -> Timeline<UsageEntry> {
        let current = entry(for: configuration, date: Date())
        var dates: Set<Date> = [current.date]
        for window in [current.snapshot?.fiveHour, current.snapshot?.sevenDay] {
            if let reset = window?.resetsAt, reset > current.date { dates.insert(reset) }
        }
        let entries = dates.sorted().map {
            UsageEntry(date: $0, snapshot: current.snapshot, model: configuration.model, window: configuration.window)
        }
        return Timeline(entries: entries, policy: .never)
    }

    private func entry(for configuration: WidgetSelectionIntent, date: Date) -> UsageEntry {
        let store = SharedUsageStore(appGroupIdentifier: Self.appGroupIdentifier)
        let snapshot: UsageSnapshot?
        if let model = configuration.model.usageModel {
            snapshot = store?.loadLatestSnapshot(for: model)
        } else {
            snapshot = store?.loadLatestSnapshot()
        }
        return UsageEntry(date: date, snapshot: snapshot, model: configuration.model, window: configuration.window)
    }
}

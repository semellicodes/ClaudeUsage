import WidgetKit
import ClaudeUsageCore

struct UsageEntry: TimelineEntry {
    let date: Date
    let snapshot: UsageSnapshot?
    var model: WidgetModelSelection = .automatic
    var window: WidgetWindowSelection = .fiveHour
    var displaySize = CGSize(width: 338, height: 158)
    var syncIssue: UsageSyncIssue?

    var syncMessage: String? {
        switch syncIssue {
        case .authenticationRequired: "Renove o login do Claude"
        case .refreshFailed: "Falha na atualização · leitura anterior"
        case nil: nil
        }
    }

    /// Somente placeholder/galeria; nunca substitui dados ausentes no desktop.
    static func preview(at date: Date, size: CGSize, model: WidgetModelSelection = .automatic,
                        window: WidgetWindowSelection = .fiveHour) -> UsageEntry {
        UsageEntry(date: date, snapshot: UsageSnapshot(schemaVersion: UsageSnapshot.currentSchemaVersion,
            capturedAt: date, claudeCodeVersion: nil, sessionID: nil, modelDisplayName: model.name,
            fiveHour: RateLimit(usedPercentage: 35, resetsAt: date.addingTimeInterval(7200)),
            sevenDay: RateLimit(usedPercentage: 62, resetsAt: date.addingTimeInterval(259200)),
            context: nil, source: .account), model: model, window: window, displaySize: size)
    }

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
        UsageEntry.preview(at: Date(), size: context.displaySize)
    }

    func snapshot(for configuration: WidgetSelectionIntent, in context: Context) async -> UsageEntry {
        Self.entry(for: configuration, in: context, date: Date())
    }

    func timeline(for configuration: WidgetSelectionIntent, in context: Context) async -> Timeline<UsageEntry> {
        Self.makeTimeline(for: Self.entry(for: configuration, in: context, date: Date()))
    }

    static func makeTimeline(for current: UsageEntry) -> Timeline<UsageEntry> {
        var dates: Set<Date> = [current.date]
        for window in [current.snapshot?.fiveHour, current.snapshot?.sevenDay] {
            if let reset = window?.resetsAt, reset > current.date { dates.insert(reset) }
        }
        let entries = dates.sorted().map {
            UsageEntry(date: $0, snapshot: current.snapshot, model: current.model,
                       window: current.window, displaySize: current.displaySize, syncIssue: current.syncIssue)
        }
        return Timeline(entries: entries, policy: .never)
    }

    static func entry(for configuration: WidgetSelectionIntent, in context: Context, date: Date) -> UsageEntry {
        if context.isPreview {
            return .preview(at: date, size: context.displaySize, model: configuration.model, window: configuration.window)
        }
        let store = SharedUsageStore(appGroupIdentifier: Self.appGroupIdentifier)
        let snapshot: UsageSnapshot?
        if let model = configuration.model.usageModel {
            snapshot = store?.loadLatestSnapshot(for: model)
        } else {
            snapshot = store?.loadLatestSnapshot()
        }
        return UsageEntry(date: date, snapshot: snapshot, model: configuration.model,
                          window: configuration.window, displaySize: context.displaySize,
                          syncIssue: store?.loadSyncIssue())
    }
}

/// Mantém as instalações originais de StaticConfiguration, que não têm intent salvo.
struct LegacyUsageTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        .preview(at: Date(), size: context.displaySize)
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        completion(UsageTimelineProvider.entry(for: WidgetSelectionIntent(), in: context, date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let entry = UsageTimelineProvider.entry(for: WidgetSelectionIntent(), in: context, date: Date())
        completion(UsageTimelineProvider.makeTimeline(for: entry))
    }
}

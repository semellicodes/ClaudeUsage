import WidgetKit
import ClaudeUsageCore

struct UsageEntry: TimelineEntry {
    let date: Date
    let snapshot: UsageSnapshot?
}

/// Lê SOMENTE o SharedUsageStore — nunca o payload bruto do statusLine, que o
/// Widget não tem (nem deveria ter) acesso. A reprodução de dados novos é
/// disparada pelo App via WidgetCenter.reloadTimelines após persistir um
/// snapshot; esta policy não faz polling.
struct UsageTimelineProvider: TimelineProvider {
    private static let appGroupIdentifier = "3U9MRVV4FR.claudeusage"

    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let now = Date()
        let snapshot = loadSnapshot()

        // Entradas adicionais nos horários de reset: a partir delas, as Views
        // (que comparam entry.date com resetsAt) passam a tratar aquela janela
        // como vencida, sem precisar de uma nova busca no store para isso.
        var dates: Set<Date> = [now]
        if let resetsAt = snapshot?.fiveHour?.resetsAt, resetsAt > now {
            dates.insert(resetsAt)
        }
        if let resetsAt = snapshot?.sevenDay?.resetsAt, resetsAt > now {
            dates.insert(resetsAt)
        }

        let entries = dates.sorted().map { UsageEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .never))
    }

    private func currentEntry() -> UsageEntry {
        UsageEntry(date: Date(), snapshot: loadSnapshot())
    }

    private func loadSnapshot() -> UsageSnapshot? {
        SharedUsageStore(appGroupIdentifier: Self.appGroupIdentifier)?.loadLatestSnapshot()
    }
}

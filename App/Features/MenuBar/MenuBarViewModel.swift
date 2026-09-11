import Foundation
import Observation
import WidgetKit
import ClaudeUsageCore

@Observable
@MainActor
final class MenuBarViewModel {
    // Precisa bater com `kind` em Widget/ClaudeUsageWidget.swift.
    private static let widgetKind = "ClaudeUsageWidget"

    private(set) var snapshot: UsageSnapshot?

    private let store: SharedUsageStore?
    private let monitor: StatusFileMonitor

    init(statusDirectoryURL: URL, appGroupIdentifier: String) {
        store = SharedUsageStore(appGroupIdentifier: appGroupIdentifier)
        let monitor = StatusFileMonitor(statusDirectoryURL: statusDirectoryURL)
        self.monitor = monitor

        // Estado inicial: o que já estiver persistido, antes mesmo do primeiro evento.
        snapshot = store?.loadLatestSnapshot()

        monitor.onSnapshotUpdate = { [weak self] newSnapshot in
            self?.handle(newSnapshot)
        }
        monitor.start()
    }

    private func handle(_ newSnapshot: UsageSnapshot) {
        snapshot = newSnapshot
        guard let store else { return }
        try? store.save(newSnapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
    }
}

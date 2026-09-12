import Foundation
import Observation
import WidgetKit
import OSLog
import ClaudeUsageCore

@Observable
@MainActor
final class MenuBarViewModel {
    // Precisa bater com `kind` em Widget/ClaudeUsageWidget.swift.
    private static let widgetKind = "ClaudeUsageWidget"
    private static let logger = Logger(subsystem: "com.paula.ClaudeUsage", category: "SharedStore")

    private(set) var snapshot: UsageSnapshot?
    private(set) var storageError: String?

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
        guard let store else {
            snapshot = newSnapshot
            storageError = "Não foi possível acessar o armazenamento dos widgets."
            return
        }
        do {
            try store.save(newSnapshot)
            snapshot = newSnapshot
            storageError = nil
            WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
        } catch {
            storageError = "Não foi possível salvar a atualização. A leitura anterior foi mantida."
            Self.logger.error("Falha ao salvar snapshot; leitura anterior preservada.")
        }
    }
}

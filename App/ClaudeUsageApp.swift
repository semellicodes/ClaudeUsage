import SwiftUI
import OSLog
import ClaudeUsageCore

@main
struct ClaudeUsageApp: App {
    private static let appGroupIdentifier = "3U9MRVV4FR.claudeusage"

    @State private var viewModel = MenuBarViewModel(
        statusDirectoryURL: Self.statusDirectoryURL,
        appGroupIdentifier: appGroupIdentifier
    )

    init() {
        Self.logAppGroupDiagnostic()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(snapshot: viewModel.snapshot)
        } label: {
            MenuBarLabel(snapshot: viewModel.snapshot)
        }
        .menuBarExtraStyle(.window)
    }

    private static var statusDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/Application Support/ClaudeUsage/status")
    }

    /// Diagnóstico registrado no startup, não uma verificação confiável isolada:
    /// `containerURL` resolve uma URL não-nil mesmo sem a entitlement correta
    /// (verificado empiricamente — ver SharedUsageStore.init?). Só documenta o
    /// fato técnico para inspeção posterior via Console/log, não decide nada.
    private static func logAppGroupDiagnostic() {
        let resolvesContainer = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) != nil
        Logger(subsystem: "com.paula.ClaudeUsage", category: "Startup")
            .notice("App Group containerURL resolvido: \(resolvesContainer, privacy: .public) (checagem não confiável isoladamente, ver SharedUsageStore.init?)")
    }
}

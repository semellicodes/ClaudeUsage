import SwiftUI
import ClaudeUsageCore

@main
struct ClaudeUsageApp: App {
    // Mesmo identificador usado pelo Widget. Ver SharedUsageStore.init? para a
    // limitação conhecida: não existe checagem confiável de App Group a partir
    // de um único processo, então nenhum diagnóstico é logado aqui no startup —
    // um log que sempre retorna o mesmo valor não ajuda a diagnosticar nada.
    private static let appGroupIdentifier = "3U9MRVV4FR.claudeusage"

    @State private var viewModel = MenuBarViewModel(
        statusDirectoryURL: Self.statusDirectoryURL,
        appGroupIdentifier: appGroupIdentifier
    )

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(snapshot: viewModel.snapshot, storageError: viewModel.storageError)
        } label: {
            MenuBarLabel(snapshot: viewModel.snapshot)
        }
        .menuBarExtraStyle(.window)
    }

    private static var statusDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/Application Support/ClaudeUsage/status")
    }
}

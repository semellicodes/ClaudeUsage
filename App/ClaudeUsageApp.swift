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
            MenuBarView(snapshot: viewModel.snapshot, referenceDate: viewModel.presentationDate,
                        storageError: viewModel.storageError)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Sincronizar Desktop e terminal", isOn: Binding(
                    get: { viewModel.accountEnabled }, set: { viewModel.setAccountEnabled($0) }
                ))
                if viewModel.accountEnabled {
                    Text("Consulta a conta a cada 5 minutos enquanto o ClaudeUsage estiver aberto.")
                        Button(viewModel.isRefreshing ? "Atualizando…" : "Atualizar agora") {
                            viewModel.refreshNow()
                        }
                        .disabled(viewModel.isRefreshing || (viewModel.nextAttempt ?? .distantPast) > viewModel.presentationDate)
                    if let message = viewModel.accountMessage { Text(message).foregroundStyle(.orange) }
                    if let next = viewModel.nextAttempt, next > Date() {
                        Text("Atualização manual liberada às \(next.formatted(date: .omitted, time: .shortened))")
                    }
                } else {
                    Text("Ao ativar, você autoriza a leitura do login do Claude Code no Chaves e o envio do token somente a https://api.anthropic.com/api/oauth/usage para consultar os limites da conta. Use a mesma conta no Desktop e no terminal.")
                }
            }
            .font(.caption)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .frame(width: 340, alignment: .leading)
        } label: {
            MenuBarLabel(snapshot: viewModel.snapshot, referenceDate: viewModel.presentationDate)
        }
        .menuBarExtraStyle(.window)
    }

    private static var statusDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/Application Support/ClaudeUsage/status")
    }
}

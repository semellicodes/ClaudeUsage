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
    private(set) var accountEnabled = UserDefaults.standard.bool(forKey: "accountUsageEnabled")
    private(set) var isRefreshing = false
    private(set) var accountMessage: String?
    private(set) var nextAttempt = UserDefaults.standard.object(forKey: "accountNextAttempt") as? Date {
        didSet { UserDefaults.standard.set(nextAttempt, forKey: "accountNextAttempt") }
    }

    private let store: SharedUsageStore?
    private let monitor: StatusFileMonitor
    private let accountClient = ClaudeAccountClient()
    private var refreshTask: Task<Void, Never>?
    private var terminalSnapshot: UsageSnapshot?
    private var failureCount = 0

    init(statusDirectoryURL: URL, appGroupIdentifier: String) {
        store = SharedUsageStore(appGroupIdentifier: appGroupIdentifier)
        let monitor = StatusFileMonitor(statusDirectoryURL: statusDirectoryURL)
        self.monitor = monitor

        // Estado inicial: o que já estiver persistido, antes mesmo do primeiro evento.
        snapshot = store?.loadLatestSnapshot()

        monitor.onSnapshotUpdate = { [weak self] newSnapshot in
            guard let self else { return }
            self.terminalSnapshot = newSnapshot
            // Uma leitura local antiga não substitui os limites atuais da conta.
            if !self.accountEnabled { self.handle(newSnapshot) }
        }
        monitor.start()
        if accountEnabled { scheduleRefresh(after: max(0, nextAttempt?.timeIntervalSinceNow ?? 0)) }
    }

    isolated deinit {
        refreshTask?.cancel()
    }

    func setAccountEnabled(_ enabled: Bool) {
        guard enabled != accountEnabled else { return }
        accountEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "accountUsageEnabled")
        refreshTask?.cancel()
        isRefreshing = false
        accountMessage = nil
        failureCount = 0
        if enabled {
            let delay = max(0, nextAttempt?.timeIntervalSinceNow ?? 0)
            scheduleRefresh(after: delay, allowInteraction: delay == 0)
        } else if let terminalSnapshot {
            handle(terminalSnapshot)
        }
    }

    func refreshNow() {
        guard accountEnabled, !isRefreshing else { return }
        if let nextAttempt, nextAttempt > Date() { return }
        scheduleRefresh(allowInteraction: true)
    }

    private func scheduleRefresh(after delay: TimeInterval = 0, allowInteraction: Bool = false) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            do {
                if delay > 0 { try await Task.sleep(for: .seconds(delay)) }
                try Task.checkCancellation()
                await self?.refreshAccount(allowInteraction: allowInteraction)
            } catch { /* Cancelamento ao desconectar ou reagendar. */ }
        }
    }

    private func refreshAccount(allowInteraction: Bool) async {
        guard accountEnabled else { return }
        Self.logger.info("Consulta dos limites da conta iniciada.")
        isRefreshing = true
        let delay: TimeInterval
        do {
            let updated = try await accountClient.fetch(allowInteraction: allowInteraction)
            guard !Task.isCancelled, accountEnabled else { return }
            handle(updated)
            Self.logger.info("Limites da conta recebidos e processados.")
            failureCount = 0
            accountMessage = nil
            // Limita também os cliques de atualização manual.
            nextAttempt = Date().addingTimeInterval(60)
            delay = ClaudeAccountClient.refreshInterval
        } catch {
            guard !Task.isCancelled, accountEnabled else { return }
            failureCount = min(failureCount + 1, 5)
            var retry = min(3600, ClaudeAccountClient.refreshInterval * pow(2, Double(failureCount - 1)))
            if case ClaudeAccountError.rateLimited(let until) = error {
                retry = max(retry, until.timeIntervalSinceNow)
            }
            switch error as? ClaudeAccountError {
            case .credentialsUnavailable, .keychainDenied, .expiredCredentials, .missingScope, .unauthorized:
                // Permite repetir logo após corrigir o login; polling automático continua lento.
                nextAttempt = Date().addingTimeInterval(30)
            default:
                nextAttempt = Date().addingTimeInterval(retry)
            }
            delay = retry
            accountMessage = Self.message(for: error)
            if let technicalError = error as? ClaudeAccountError {
                Self.logger.error("Consulta dos limites falhou: \(String(describing: technicalError), privacy: .public)")
            }
        }
        isRefreshing = false
        scheduleRefresh(after: delay)
    }

    private static func message(for error: Error) -> String {
        switch error as? ClaudeAccountError {
        case .credentialsUnavailable:
            "Execute claude auth login no Terminal, entre na mesma conta do Desktop e atualize aqui."
        case .keychainDenied:
            "Acesso ao Chaves não autorizado. Clique em Atualizar para permitir a leitura do login do Claude."
        case .expiredCredentials, .unauthorized, .missingScope:
            "Login vencido ou sem acesso ao uso. Execute claude auth login no Terminal e depois atualize aqui."
        case .rateLimited:
            "A Anthropic pediu uma pausa. A última leitura foi mantida; a consulta será repetida depois."
        case .invalidResponse:
            "Resposta de uso incompatível. A última leitura foi mantida."
        default:
            "Não foi possível consultar a conta. A última leitura foi mantida; haverá nova tentativa automática."
        }
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

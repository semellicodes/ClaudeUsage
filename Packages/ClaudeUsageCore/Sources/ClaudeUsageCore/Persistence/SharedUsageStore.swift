import Foundation

/// Lê/escreve o `UsageSnapshot` compartilhado entre App e Widget via App Group.
/// Não conhece SwiftUI nem WidgetKit — só Foundation.
///
/// Invariante documentada que justifica `@unchecked Sendable`: `UserDefaults`
/// não conforma a `Sendable` no SDK, mas a Apple documenta a classe como
/// thread-safe (leitura/escrita concorrentes são suportadas). Sem essa
/// garantia documentada, `@unchecked Sendable` não seria aceitável aqui.
public struct SharedUsageStore: @unchecked Sendable {
    private static let snapshotKey = "latestUsageSnapshot"
    private static let syncIssueKey = "usageSyncIssue"

    private let userDefaults: UserDefaults

    /// `appGroupIdentifier` nunca é fixado no tipo: cada chamador decide o grupo,
    /// e os testes usam um identificador isolado sem tocar no grupo real.
    ///
    /// Limitação conhecida e verificada empiricamente (não apenas suposta):
    /// `UserDefaults(suiteName:)` só retorna `nil` para um suite name vazio ou
    /// degenerado. Um identificador errado, ou a ausência da entitlement
    /// `com.apple.security.application-groups` correta no processo sandboxed,
    /// NÃO faz este init falhar — `UserDefaults` continua non-nil e
    /// leituras/escritas continuam funcionando localmente, só que num domínio
    /// que o outro processo nunca vê. Confirmei isso com um teste manual
    /// (dois processos assinados fora do projeto, mesmas entitlements do
    /// App/Widget reais): escrita não vinga no outro lado sem crash nem erro,
    /// `loadLatestSnapshot()` simplesmente nunca encontra o dado novo.
    /// `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`
    /// também NÃO serve como verificação prévia — testei e ele retorna uma URL
    /// não-nil para qualquer identificador, com ou sem a entitlement, sandboxed
    /// ou não; a API só calcula o caminho teórico, não valida direito de acesso.
    /// Não existe checagem confiável de um único processo isolado — só um teste
    /// cruzado real (escrever de um lado, ler do outro) prova a integração.
    public init?(appGroupIdentifier: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return nil
        }
        self.userDefaults = userDefaults
    }

    public func save(_ snapshot: UsageSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        userDefaults.set(data, forKey: Self.snapshotKey)
        if let model = UsageModel(displayName: snapshot.modelDisplayName) {
            userDefaults.set(data, forKey: Self.snapshotKey + "." + model.rawValue)
        }
        setSyncIssue(nil)
    }

    /// Estado técnico separado: falha de atualização não muda capturedAt nem os percentuais.
    public func setSyncIssue(_ issue: UsageSyncIssue?) {
        userDefaults.set(issue?.rawValue, forKey: Self.syncIssueKey)
    }

    public func loadSyncIssue() -> UsageSyncIssue? {
        userDefaults.string(forKey: Self.syncIssueKey).flatMap(UsageSyncIssue.init(rawValue:))
    }

    /// `nil` cobre igualmente: nada gravado ainda, dado corrompido/ilegível,
    /// ou `schemaVersion` diferente da atual (V1 não migra formatos antigos).
    public func loadLatestSnapshot() -> UsageSnapshot? {
        loadSnapshot(key: Self.snapshotKey)
    }

    /// Última leitura recebida com este modelo; não representa uma cota exclusiva dele.
    public func loadLatestSnapshot(for model: UsageModel) -> UsageSnapshot? {
        if let latest = loadLatestSnapshot(), latest.source == .account {
            return latest.selecting(model)
        }
        if let snapshot = loadSnapshot(key: Self.snapshotKey + "." + model.rawValue) {
            return snapshot
        }
        // Compatibilidade com o snapshot único das versões anteriores.
        guard let latest = loadLatestSnapshot(),
              UsageModel(displayName: latest.modelDisplayName) == model else { return nil }
        return latest
    }

    private func loadSnapshot(key: String) -> UsageSnapshot? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        guard let snapshot = try? JSONDecoder().decode(UsageSnapshot.self, from: data) else {
            return nil
        }
        guard snapshot.schemaVersion == UsageSnapshot.currentSchemaVersion else {
            return nil
        }
        return snapshot
    }
}

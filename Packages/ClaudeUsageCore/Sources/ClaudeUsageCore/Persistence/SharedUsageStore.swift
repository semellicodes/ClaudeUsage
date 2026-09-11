import Foundation

/// Lê/escreve o `UsageSnapshot` compartilhado entre App e Widget via App Group.
/// Não conhece SwiftUI nem WidgetKit — só Foundation.
/// `@unchecked Sendable`: `UserDefaults` não é `Sendable` no SDK, mas é
/// documentada pela Apple como thread-safe.
public struct SharedUsageStore: @unchecked Sendable {
    private static let snapshotKey = "latestUsageSnapshot"

    private let userDefaults: UserDefaults

    /// `appGroupIdentifier` nunca é fixado no tipo: cada chamador decide o grupo,
    /// e os testes usam um identificador isolado sem tocar no grupo real.
    public init?(appGroupIdentifier: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return nil
        }
        self.userDefaults = userDefaults
    }

    public func save(_ snapshot: UsageSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        userDefaults.set(data, forKey: Self.snapshotKey)
    }

    /// `nil` cobre igualmente: nada gravado ainda, dado corrompido/ilegível,
    /// ou `schemaVersion` diferente da atual (V1 não migra formatos antigos).
    public func loadLatestSnapshot() -> UsageSnapshot? {
        guard let data = userDefaults.data(forKey: Self.snapshotKey) else {
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

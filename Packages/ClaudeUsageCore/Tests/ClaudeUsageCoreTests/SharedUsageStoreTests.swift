import Foundation
import Testing
import ClaudeUsageCore

private func withIsolatedStore(_ body: (SharedUsageStore, String) throws -> Void) throws {
    let suiteName = "com.claudeusage.tests.\(UUID().uuidString)"
    defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }

    let store = try #require(SharedUsageStore(appGroupIdentifier: suiteName))
    try body(store, suiteName)
}

private let sampleSnapshot = UsageSnapshot(
    schemaVersion: UsageSnapshot.currentSchemaVersion,
    capturedAt: Date(timeIntervalSince1970: 1_738_400_000),
    claudeCodeVersion: "2.1.90",
    sessionID: "abc123",
    modelDisplayName: "Opus",
    fiveHour: RateLimit(usedPercentage: 23.5, resetsAt: Date(timeIntervalSince1970: 1_738_425_600)),
    sevenDay: nil,
    context: ContextUsage(inputTokens: 100, outputTokens: 20, windowSize: 200_000, usedPercentage: 8, remainingPercentage: 92)
)

@Suite("SharedUsageStore")
struct SharedUsageStoreTests {

    @Test("seleção de modelo preserva leituras independentes e o automático acompanha a última")
    func modelSnapshots() throws {
        try withIsolatedStore { store, _ in
            try store.save(sampleSnapshot)
            let sonnet = UsageSnapshot(
                schemaVersion: 1, capturedAt: sampleSnapshot.capturedAt.addingTimeInterval(60),
                claudeCodeVersion: nil, sessionID: nil, modelDisplayName: "Sonnet 5",
                fiveHour: nil, sevenDay: nil, context: nil
            )
            try store.save(sonnet)
            #expect(store.loadLatestSnapshot() == sonnet)
            #expect(store.loadLatestSnapshot(for: .sonnet) == sonnet)
            #expect(store.loadLatestSnapshot(for: .opus) == sampleSnapshot)
            // A ausência de 5h continua sendo ausência, sem copiar outra leitura.
            #expect(store.loadLatestSnapshot(for: .sonnet)?.fiveHour == nil)
        }
    }

    @Test("modelo sem leitura não recebe os dados de outro modelo")
    func missingModel() throws {
        try withIsolatedStore { store, _ in
            try store.save(sampleSnapshot)
            #expect(store.loadLatestSnapshot(for: .sonnet) == nil)
        }
    }

    @Test("snapshot legado é aproveitado somente para o modelo correspondente")
    func legacyModelSnapshot() throws {
        try withIsolatedStore { store, suite in
            let defaults = try #require(UserDefaults(suiteName: suite))
            defaults.set(try JSONEncoder().encode(sampleSnapshot), forKey: "latestUsageSnapshot")
            #expect(store.loadLatestSnapshot(for: .opus) == sampleSnapshot)
            #expect(store.loadLatestSnapshot(for: .sonnet) == nil)
        }
    }

    @Test("reconhece famílias sem fixar versão nem aceitar nomes parecidos")
    func modelNames() {
        #expect(UsageModel(displayName: "Claude Sonnet 5") == .sonnet)
        #expect(UsageModel(displayName: "OPUS 5") == .opus)
        #expect(UsageModel(displayName: "Haiku") == nil)
        #expect(UsageModel(displayName: "NotSonnet") == nil)
        #expect(UsageModel(displayName: nil) == nil)
    }

    @Test("Shared Store vazio retorna nil")
    func emptyStoreReturnsNil() throws {
        try withIsolatedStore { store, _ in
            #expect(store.loadLatestSnapshot() == nil)
        }
    }

    @Test("save seguido de loadLatestSnapshot devolve o mesmo snapshot")
    func saveThenLoadRoundTrips() throws {
        try withIsolatedStore { store, _ in
            try store.save(sampleSnapshot)
            #expect(store.loadLatestSnapshot() == sampleSnapshot)
        }
    }

    @Test("snapshot corrompido (Data que não decodifica) retorna nil")
    func corruptedSnapshotReturnsNil() throws {
        try withIsolatedStore { _, suiteName in
            let defaults = try #require(UserDefaults(suiteName: suiteName))
            defaults.set(Data([0xFF, 0x00, 0x13, 0x37]), forKey: "latestUsageSnapshot")

            let store = try #require(SharedUsageStore(appGroupIdentifier: suiteName))
            #expect(store.loadLatestSnapshot() == nil)
        }
    }

    @Test("schemaVersion incompatível retorna nil, não uma migração implícita")
    func incompatibleSchemaVersionReturnsNil() throws {
        try withIsolatedStore { _, suiteName in
            let futureSnapshot = UsageSnapshot(
                schemaVersion: UsageSnapshot.currentSchemaVersion + 1,
                capturedAt: sampleSnapshot.capturedAt,
                claudeCodeVersion: sampleSnapshot.claudeCodeVersion,
                sessionID: sampleSnapshot.sessionID,
                modelDisplayName: sampleSnapshot.modelDisplayName,
                fiveHour: sampleSnapshot.fiveHour,
                sevenDay: sampleSnapshot.sevenDay,
                context: sampleSnapshot.context
            )
            let data = try JSONEncoder().encode(futureSnapshot)
            let defaults = try #require(UserDefaults(suiteName: suiteName))
            defaults.set(data, forKey: "latestUsageSnapshot")

            let store = try #require(SharedUsageStore(appGroupIdentifier: suiteName))
            #expect(store.loadLatestSnapshot() == nil)
        }
    }
}

import Foundation
import Testing
import ClaudeUsageCore

@Suite("UsageSnapshot Codable")
struct UsageSnapshotCodableTests {
    @Test("round trip de encode/decode preserva o valor")
    func roundTrip() throws {
        let original = UsageSnapshot(
            schemaVersion: UsageSnapshot.currentSchemaVersion,
            capturedAt: Date(timeIntervalSince1970: 1_738_400_000),
            claudeCodeVersion: "2.1.90",
            sessionID: "abc123",
            modelDisplayName: "Opus",
            fiveHour: RateLimit(usedPercentage: 23.5, resetsAt: Date(timeIntervalSince1970: 1_738_425_600)),
            sevenDay: nil,
            context: ContextUsage(
                inputTokens: 100,
                outputTokens: 20,
                windowSize: 200_000,
                usedPercentage: 8,
                remainingPercentage: 92
            )
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsageSnapshot.self, from: encoded)

        #expect(decoded == original)
    }

    @Test("round trip com todos os campos opcionais nil")
    func roundTripAllNil() throws {
        let original = UsageSnapshot(
            schemaVersion: UsageSnapshot.currentSchemaVersion,
            capturedAt: Date(timeIntervalSince1970: 0),
            claudeCodeVersion: nil,
            sessionID: nil,
            modelDisplayName: nil,
            fiveHour: nil,
            sevenDay: nil,
            context: nil
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsageSnapshot.self, from: encoded)

        #expect(decoded == original)
    }
}

import Foundation
import Testing
import ClaudeUsageCore

private let referenceCapturedAt = Date(timeIntervalSince1970: 1_738_400_000)

@Suite("ClaudeStatusMapper")
struct ClaudeStatusMapperTests {

    @Test("payload completo mapeia todos os campos")
    func fullPayload() throws {
        let data = try Fixture.data("full_payload")
        let snapshot = try #require(ClaudeStatusMapper.map(jsonData: data, capturedAt: referenceCapturedAt))

        #expect(snapshot.claudeCodeVersion == "2.1.90")
        #expect(snapshot.sessionID == "abc123-def456")
        #expect(snapshot.modelDisplayName == "Opus")
        #expect(snapshot.capturedAt == referenceCapturedAt)

        let fiveHour = try #require(snapshot.fiveHour)
        #expect(fiveHour.usedPercentage == 23.5)
        #expect(fiveHour.resetsAt == Date(timeIntervalSince1970: 1_738_425_600))

        let sevenDay = try #require(snapshot.sevenDay)
        #expect(sevenDay.usedPercentage == 41.2)
        #expect(sevenDay.resetsAt == Date(timeIntervalSince1970: 1_738_857_600))

        let context = try #require(snapshot.context)
        #expect(context.inputTokens == 15500)
        #expect(context.outputTokens == 1200)
        #expect(context.windowSize == 200_000)
        #expect(context.usedPercentage == 8)
        #expect(context.remainingPercentage == 92)
    }

    @Test("rate_limits ausente resulta em ambas as janelas nil")
    func rateLimitsMissing() throws {
        let data = try Fixture.data("rate_limits_missing")
        let snapshot = try #require(ClaudeStatusMapper.map(jsonData: data, capturedAt: referenceCapturedAt))
        #expect(snapshot.fiveHour == nil)
        #expect(snapshot.sevenDay == nil)
    }

    @Test("apenas five_hour presente")
    func fiveHourOnly() throws {
        let data = try Fixture.data("rate_limits_five_hour_only")
        let snapshot = try #require(ClaudeStatusMapper.map(jsonData: data, capturedAt: referenceCapturedAt))
        #expect(snapshot.fiveHour != nil)
        #expect(snapshot.sevenDay == nil)
    }

    @Test("apenas seven_day presente")
    func sevenDayOnly() throws {
        let data = try Fixture.data("rate_limits_seven_day_only")
        let snapshot = try #require(ClaudeStatusMapper.map(jsonData: data, capturedAt: referenceCapturedAt))
        #expect(snapshot.fiveHour == nil)
        #expect(snapshot.sevenDay != nil)
    }

    @Test("percentuais de contexto null não quebram o decoding")
    func contextPercentagesNull() throws {
        let data = try Fixture.data("context_used_percentage_null")
        let snapshot = try #require(ClaudeStatusMapper.map(jsonData: data, capturedAt: referenceCapturedAt))
        let context = try #require(snapshot.context)
        #expect(context.usedPercentage == nil)
        #expect(context.remainingPercentage == nil)
        #expect(context.inputTokens == 0)
        #expect(context.outputTokens == 0)
    }

    @Test("context_window totalmente ausente resulta em context nil")
    func contextWindowAbsent() throws {
        let data = try Fixture.data("context_window_absent")
        let snapshot = try #require(ClaudeStatusMapper.map(jsonData: data, capturedAt: referenceCapturedAt))
        #expect(snapshot.context == nil)
    }

    @Test("campos desconhecidos não quebram o decoding")
    func unknownFields() throws {
        let data = try Fixture.data("unknown_fields")
        let snapshot = try #require(ClaudeStatusMapper.map(jsonData: data, capturedAt: referenceCapturedAt))
        #expect(snapshot.sessionID == "xyz")
        #expect(snapshot.modelDisplayName == "Sonnet")
        #expect(snapshot.fiveHour != nil)
    }

    @Test("JSON inválido resulta em nil, sem crash")
    func invalidJSON() throws {
        let data = try Fixture.data("invalid")
        let snapshot = ClaudeStatusMapper.map(jsonData: data, capturedAt: referenceCapturedAt)
        #expect(snapshot == nil)
    }

    @Test("percentuais fora de 0...100 são normalizados defensivamente")
    func anomalousPercentages() throws {
        let data = try Fixture.data("rate_limits_anomalous_percentage")
        let snapshot = try #require(ClaudeStatusMapper.map(jsonData: data, capturedAt: referenceCapturedAt))

        let fiveHour = try #require(snapshot.fiveHour)
        #expect(fiveHour.usedPercentage == 100)

        let sevenDay = try #require(snapshot.sevenDay)
        #expect(sevenDay.usedPercentage == 0)

        let context = try #require(snapshot.context)
        #expect(context.usedPercentage == 100)
        #expect(context.remainingPercentage == 0)
    }

    @Test("resets_at no passado é preservado sem filtragem no Mapper")
    func resetInThePast() throws {
        let data = try Fixture.data("reset_in_the_past")
        let snapshot = try #require(ClaudeStatusMapper.map(jsonData: data, capturedAt: referenceCapturedAt))
        let fiveHour = try #require(snapshot.fiveHour)
        let farFutureReference = Date(timeIntervalSince1970: 2_000_000_000)
        #expect(fiveHour.resetsAt < farFutureReference)
    }
}

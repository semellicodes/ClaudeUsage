import Foundation

public enum UsageSource: String, Codable, Sendable {
    case account
}

public struct UsageSnapshot: Equatable, Sendable, Codable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let capturedAt: Date
    public let claudeCodeVersion: String?
    public let sessionID: String?
    public let modelDisplayName: String?
    public let fiveHour: RateLimit?
    public let sevenDay: RateLimit?
    public let context: ContextUsage?
    /// nil preserva a compatibilidade com snapshots antigos de statusLine.
    public let source: UsageSource?
    public let sevenDaySonnet: RateLimit?
    public let sevenDayOpus: RateLimit?

    public init(
        schemaVersion: Int,
        capturedAt: Date,
        claudeCodeVersion: String?,
        sessionID: String?,
        modelDisplayName: String?,
        fiveHour: RateLimit?,
        sevenDay: RateLimit?,
        context: ContextUsage?,
        source: UsageSource? = nil,
        sevenDaySonnet: RateLimit? = nil,
        sevenDayOpus: RateLimit? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.capturedAt = capturedAt
        self.claudeCodeVersion = claudeCodeVersion
        self.sessionID = sessionID
        self.modelDisplayName = modelDisplayName
        self.fiveHour = fiveHour
        self.sevenDay = sevenDay
        self.context = context
        self.source = source
        self.sevenDaySonnet = sevenDaySonnet
        self.sevenDayOpus = sevenDayOpus
    }

    /// A janela de 5h é compartilhada; só usa semanal por modelo se a API o informar.
    public func selecting(_ model: UsageModel) -> UsageSnapshot {
        guard source == .account else { return self }
        let scoped = model == .sonnet ? sevenDaySonnet : sevenDayOpus
        return UsageSnapshot(schemaVersion: schemaVersion, capturedAt: capturedAt,
            claudeCodeVersion: nil, sessionID: nil,
            modelDisplayName: model == .sonnet ? "Sonnet" : "Opus",
            fiveHour: fiveHour, sevenDay: scoped ?? sevenDay, context: nil,
            source: .account, sevenDaySonnet: sevenDaySonnet, sevenDayOpus: sevenDayOpus)
    }
}

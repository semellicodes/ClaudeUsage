import Foundation

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

    public init(
        schemaVersion: Int,
        capturedAt: Date,
        claudeCodeVersion: String?,
        sessionID: String?,
        modelDisplayName: String?,
        fiveHour: RateLimit?,
        sevenDay: RateLimit?,
        context: ContextUsage?
    ) {
        self.schemaVersion = schemaVersion
        self.capturedAt = capturedAt
        self.claudeCodeVersion = claudeCodeVersion
        self.sessionID = sessionID
        self.modelDisplayName = modelDisplayName
        self.fiveHour = fiveHour
        self.sevenDay = sevenDay
        self.context = context
    }
}

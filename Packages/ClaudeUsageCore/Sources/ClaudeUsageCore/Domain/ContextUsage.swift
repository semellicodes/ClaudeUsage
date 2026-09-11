import Foundation

public struct ContextUsage: Equatable, Sendable, Codable {
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let windowSize: Int?
    public let usedPercentage: Double?
    public let remainingPercentage: Double?

    public init(
        inputTokens: Int?,
        outputTokens: Int?,
        windowSize: Int?,
        usedPercentage: Double?,
        remainingPercentage: Double?
    ) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.windowSize = windowSize
        self.usedPercentage = usedPercentage
        self.remainingPercentage = remainingPercentage
    }
}

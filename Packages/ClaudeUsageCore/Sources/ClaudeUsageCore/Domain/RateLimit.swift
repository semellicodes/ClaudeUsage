import Foundation

public struct RateLimit: Equatable, Sendable, Codable {
    public let usedPercentage: Double
    public let resetsAt: Date

    public init(usedPercentage: Double, resetsAt: Date) {
        self.usedPercentage = usedPercentage
        self.resetsAt = resetsAt
    }

    public var remainingPercentage: Double {
        min(max(100 - usedPercentage, 0), 100)
    }
}

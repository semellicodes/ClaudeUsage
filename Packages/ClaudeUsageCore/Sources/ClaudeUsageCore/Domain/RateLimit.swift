import Foundation

public struct RateLimit: Equatable, Sendable, Codable {
    public let usedPercentage: Double
    /// A conta pode informar uso (inclusive 0%) sem uma janela de reset ativa.
    public let resetsAt: Date?

    public init(usedPercentage: Double, resetsAt: Date?) {
        self.usedPercentage = usedPercentage
        self.resetsAt = resetsAt
    }

    public var remainingPercentage: Double {
        min(max(100 - usedPercentage, 0), 100)
    }

    public func hasReset(at date: Date) -> Bool {
        resetsAt.map { $0 <= date } ?? false
    }
}

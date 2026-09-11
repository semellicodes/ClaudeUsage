import Foundation
import Testing
import ClaudeUsageCore

@Suite("RateLimit")
struct RateLimitTests {
    @Test("remainingPercentage é o complemento de usedPercentage")
    func remainingComplement() {
        let rateLimit = RateLimit(usedPercentage: 23.5, resetsAt: Date(timeIntervalSince1970: 0))
        #expect(rateLimit.remainingPercentage == 76.5)
    }

    @Test("remainingPercentage nunca fica abaixo de 0 mesmo com usedPercentage acima de 100")
    func remainingClampedLowerBound() {
        let rateLimit = RateLimit(usedPercentage: 150, resetsAt: Date(timeIntervalSince1970: 0))
        #expect(rateLimit.remainingPercentage == 0)
    }

    @Test("remainingPercentage nunca ultrapassa 100 mesmo com usedPercentage negativo")
    func remainingClampedUpperBound() {
        let rateLimit = RateLimit(usedPercentage: -30, resetsAt: Date(timeIntervalSince1970: 0))
        #expect(rateLimit.remainingPercentage == 100)
    }
}

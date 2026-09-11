import Foundation

/// Única fronteira entre o payload bruto do statusLine e o Domain.
/// `map(jsonData:capturedAt:)` é a única API pública: se o JSON não decodificar,
/// retorna `nil` e cabe ao chamador preservar o último snapshot válido.
public enum ClaudeStatusMapper {
    public static func map(jsonData: Data, capturedAt: Date) -> UsageSnapshot? {
        guard let payload = try? JSONDecoder().decode(ClaudeStatusPayload.self, from: jsonData) else {
            return nil
        }
        return map(payload: payload, capturedAt: capturedAt)
    }

    static func map(payload: ClaudeStatusPayload, capturedAt: Date) -> UsageSnapshot {
        UsageSnapshot(
            schemaVersion: UsageSnapshot.currentSchemaVersion,
            capturedAt: capturedAt,
            claudeCodeVersion: payload.version,
            sessionID: payload.sessionID,
            modelDisplayName: payload.model?.displayName,
            fiveHour: mapRateLimit(payload.rateLimits?.fiveHour),
            sevenDay: mapRateLimit(payload.rateLimits?.sevenDay),
            context: mapContext(payload.contextWindow)
        )
    }

    private static func mapRateLimit(_ window: ClaudeStatusPayload.RateLimitWindow?) -> RateLimit? {
        guard let window,
              let usedPercentage = window.usedPercentage,
              let resetsAt = window.resetsAt,
              usedPercentage.isFinite,
              resetsAt.isFinite
        else {
            return nil
        }
        return RateLimit(
            usedPercentage: clampPercentage(usedPercentage),
            resetsAt: Date(timeIntervalSince1970: resetsAt)
        )
    }

    private static func mapContext(_ window: ClaudeStatusPayload.ContextWindow?) -> ContextUsage? {
        guard let window,
              let windowSize = window.contextWindowSize,
              windowSize > 0
        else {
            return nil
        }
        return ContextUsage(
            inputTokens: window.totalInputTokens ?? 0,
            outputTokens: window.totalOutputTokens ?? 0,
            windowSize: windowSize,
            usedPercentage: normalizedPercentage(window.usedPercentage),
            remainingPercentage: normalizedPercentage(window.remainingPercentage)
        )
    }

    private static func normalizedPercentage(_ value: Double?) -> Double? {
        guard let value, value.isFinite else { return nil }
        return clampPercentage(value)
    }

    private static func clampPercentage(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }
}

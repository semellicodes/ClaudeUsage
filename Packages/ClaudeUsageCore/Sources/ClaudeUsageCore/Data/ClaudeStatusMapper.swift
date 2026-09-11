import Foundation

/// Única fronteira entre o payload bruto do statusLine e o Domain.
public enum ClaudeStatusMapper {
    /// Falha ao decodificar o JSON do statusLine.
    /// `reason` é a descrição técnica do `DecodingError` (tipos/chaves esperados),
    /// nunca o conteúdo do payload — seguro para log via `OSLog.Logger`.
    public enum MappingError: Error, Equatable, Sendable {
        case invalidJSON(reason: String)
    }

    /// `nil` nunca aparece aqui: falha vira `.failure`, com o motivo técnico,
    /// para quem chama decidir manter o último snapshot válido e logar com segurança.
    public static func map(jsonData: Data, capturedAt: Date) -> Result<UsageSnapshot, MappingError> {
        do {
            let payload = try JSONDecoder().decode(ClaudeStatusPayload.self, from: jsonData)
            return .success(map(payload: payload, capturedAt: capturedAt))
        } catch {
            return .failure(.invalidJSON(reason: String(describing: error)))
        }
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

    /// Só retorna `nil` quando `context_window` está totalmente ausente do payload.
    /// Cada campo dentro do bloco é validado independentemente: `used_percentage`
    /// (o percentual oficial) sobrevive mesmo sem `context_window_size`, e um
    /// campo ausente/ inválido vira `nil` nesse campo, nunca um valor inventado.
    private static func mapContext(_ window: ClaudeStatusPayload.ContextWindow?) -> ContextUsage? {
        guard let window else { return nil }
        return ContextUsage(
            inputTokens: validTokenCount(window.totalInputTokens),
            outputTokens: validTokenCount(window.totalOutputTokens),
            windowSize: validWindowSize(window.contextWindowSize),
            usedPercentage: normalizedPercentage(window.usedPercentage),
            remainingPercentage: normalizedPercentage(window.remainingPercentage)
        )
    }

    private static func validTokenCount(_ value: Int?) -> Int? {
        guard let value, value >= 0 else { return nil }
        return value
    }

    private static func validWindowSize(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return value
    }

    private static func normalizedPercentage(_ value: Double?) -> Double? {
        guard let value, value.isFinite else { return nil }
        return clampPercentage(value)
    }

    private static func clampPercentage(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }
}

import Foundation

/// Contrato da API de uso da conta, separado do JSON do statusLine.
struct ClaudeAccountPayload: Decodable {
    struct Window: Decodable {
        let utilization: Double?
        let resets_at: String?

        func rateLimit() throws -> RateLimit? {
            guard let utilization else { return nil }
            guard utilization.isFinite else {
                throw ClaudeAccountError.invalidResponse
            }
            guard let resets_at else {
                return RateLimit(usedPercentage: min(100, max(0, utilization)), resetsAt: nil)
            }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var date = formatter.date(from: resets_at)
            if date == nil {
                formatter.formatOptions = [.withInternetDateTime]
                date = formatter.date(from: resets_at)
            }
            guard let date else { throw ClaudeAccountError.invalidResponse }
            return RateLimit(usedPercentage: min(100, max(0, utilization)), resetsAt: date)
        }
    }

    let five_hour: Window?
    let seven_day: Window?
    let seven_day_sonnet: Window?
    let seven_day_opus: Window?

    static func snapshot(from data: Data, at date: Date) throws -> UsageSnapshot {
        do {
            // Um objeto de erro inesperado não pode apagar a última leitura válida.
            let keys = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard keys?["five_hour"] != nil || keys?["seven_day"] != nil else {
                throw ClaudeAccountError.invalidResponse
            }
            let payload = try JSONDecoder().decode(Self.self, from: data)
            return try UsageSnapshot(schemaVersion: UsageSnapshot.currentSchemaVersion,
                capturedAt: date, claudeCodeVersion: nil, sessionID: nil,
                modelDisplayName: nil, fiveHour: payload.five_hour?.rateLimit(),
                sevenDay: payload.seven_day?.rateLimit(), context: nil, source: .account,
                sevenDaySonnet: payload.seven_day_sonnet?.rateLimit(),
                sevenDayOpus: payload.seven_day_opus?.rateLimit())
        } catch { throw ClaudeAccountError.invalidResponse }
    }
}

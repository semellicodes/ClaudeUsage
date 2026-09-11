import Foundation

/// Espelha apenas os campos do JSON do statusLine relevantes para o app.
/// Chaves desconhecidas são ignoradas automaticamente pelo `Decodable`.
struct ClaudeStatusPayload: Decodable {
    struct Model: Decodable {
        let displayName: String?

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
        }
    }

    struct RateLimitWindow: Decodable {
        let usedPercentage: Double?
        let resetsAt: Double?

        enum CodingKeys: String, CodingKey {
            case usedPercentage = "used_percentage"
            case resetsAt = "resets_at"
        }
    }

    struct RateLimits: Decodable {
        let fiveHour: RateLimitWindow?
        let sevenDay: RateLimitWindow?

        enum CodingKeys: String, CodingKey {
            case fiveHour = "five_hour"
            case sevenDay = "seven_day"
        }
    }

    struct ContextWindow: Decodable {
        let totalInputTokens: Int?
        let totalOutputTokens: Int?
        let contextWindowSize: Int?
        let usedPercentage: Double?
        let remainingPercentage: Double?

        enum CodingKeys: String, CodingKey {
            case totalInputTokens = "total_input_tokens"
            case totalOutputTokens = "total_output_tokens"
            case contextWindowSize = "context_window_size"
            case usedPercentage = "used_percentage"
            case remainingPercentage = "remaining_percentage"
        }
    }

    let version: String?
    let sessionID: String?
    let model: Model?
    let rateLimits: RateLimits?
    let contextWindow: ContextWindow?

    enum CodingKeys: String, CodingKey {
        case version
        case sessionID = "session_id"
        case model
        case rateLimits = "rate_limits"
        case contextWindow = "context_window"
    }
}

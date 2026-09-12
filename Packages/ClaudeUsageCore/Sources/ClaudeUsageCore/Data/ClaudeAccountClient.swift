import Foundation

public enum ClaudeAccountError: Error, Equatable, Sendable {
    case credentialsUnavailable
    case keychainDenied
    case expiredCredentials
    case missingScope
    case unauthorized
    case rateLimited(until: Date)
    case http(Int)
    case invalidResponse
    case connectionFailed
}

/// Consulta apenas limites: não envia mensagens nem consome inferência.
public actor ClaudeAccountClient {
    public typealias Credentials = @Sendable (Bool, Date) throws -> String
    public typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)
    public static let refreshInterval: TimeInterval = 300
    private let credentials: Credentials
    private let transport: Transport

    public init(credentials: @escaping Credentials = { allowInteraction, now in
                    try ClaudeOAuthCredentials.accessToken(allowInteraction: allowInteraction, now: now)
                },
                transport: Transport? = nil) {
        self.credentials = credentials
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        let session = URLSession(configuration: configuration, delegate: NoUsageRedirects(), delegateQueue: nil)
        self.transport = transport ?? { request in try await session.data(for: request) }
    }

    public func fetch(allowInteraction: Bool = false, now: Date = Date()) async throws -> UsageSnapshot {
        let token = try credentials(allowInteraction, now)
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else {
            throw ClaudeAccountError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let data: Data
        let response: URLResponse
        do { (data, response) = try await transport(request) }
        catch is CancellationError { throw CancellationError() }
        catch { throw ClaudeAccountError.connectionFailed }
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse else { throw ClaudeAccountError.invalidResponse }
        switch http.statusCode {
        case 200: break
        case 401, 403: throw ClaudeAccountError.unauthorized
        case 429:
            let retry = Self.retryDate(http.value(forHTTPHeaderField: "Retry-After"), now: now)
            throw ClaudeAccountError.rateLimited(until: retry)
        default: throw ClaudeAccountError.http(http.statusCode)
        }
        guard data.count <= 1_048_576 else { throw ClaudeAccountError.invalidResponse }
        return try ClaudeAccountPayload.snapshot(from: data, at: now)
    }

    static func retryDate(_ header: String?, now: Date) -> Date {
        if let header, let seconds = Double(header), seconds.isFinite, seconds >= 0 {
            return now.addingTimeInterval(max(refreshInterval, seconds))
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        let serverDate = header.flatMap { formatter.date(from: $0) }
        return max(serverDate ?? now, now.addingTimeInterval(refreshInterval))
    }
}

private final class NoUsageRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

import Foundation
import Testing
@testable import ClaudeUsageCore

@Suite("Uso da conta sem terminal ativo")
struct ClaudeAccountTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let payload = Data("""
    {"five_hour":{"utilization":0,"resets_at":"2027-01-15T10:00:00.000Z"},
     "seven_day":{"utilization":20,"resets_at":"2027-01-20T10:00:00Z"},
     "seven_day_sonnet":{"utilization":32,"resets_at":"2027-01-20T10:00:00Z"},
     "seven_day_opus":null,"extra_field":{"ignored":true}}
    """.utf8)

    @Test("Consulta somente o destino fixo e persiste limites reais por modelo")
    func accountThroughStore() async throws {
        let body = payload
        let client = ClaudeAccountClient(credentials: { _, _ in "synthetic-test-token" }, transport: { request in
            #expect(request.url?.absoluteString == "https://api.anthropic.com/api/oauth/usage")
            #expect(request.httpMethod == "GET")
            #expect(request.httpBody == nil)
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-test-token")
            #expect(request.value(forHTTPHeaderField: "anthropic-beta") == "oauth-2025-04-20")
            let url = try #require(request.url)
            return (body, try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)))
        })
        let snapshot = try await client.fetch(now: now)
        #expect(snapshot.fiveHour?.usedPercentage == 0)
        #expect(snapshot.fiveHour?.resetsAt == Date(timeIntervalSince1970: 1_800_007_200))
        #expect(snapshot.source == .account)
        #expect(snapshot.context == nil)
        #expect(snapshot.sessionID == nil)
        #expect(snapshot.capturedAt == now)
        let suite = "com.claudeusage.account-tests.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let store = try #require(SharedUsageStore(appGroupIdentifier: suite))
        try store.save(snapshot)
        #expect(store.loadLatestSnapshot(for: .sonnet)?.sevenDay?.usedPercentage == 32)
        #expect(store.loadLatestSnapshot(for: .opus)?.sevenDay?.usedPercentage == 20)
        #expect(store.loadLatestSnapshot(for: .sonnet)?.fiveHour == store.loadLatestSnapshot(for: .opus)?.fiveHour)
        #expect(store.loadLatestSnapshot() == snapshot)
    }

    @Test("Janela ausente permanece ausente", arguments: [
        "{\"five_hour\":null,\"seven_day\":null}",
        "{\"seven_day\":null}",
        "{\"five_hour\":{\"utilization\":null,\"resets_at\":null}}"
    ])
    func missingWindows(json: String) throws {
        let snapshot = try ClaudeAccountPayload.snapshot(from: Data(json.utf8), at: now)
        #expect(snapshot.fiveHour == nil)
        #expect(snapshot.sevenDay == nil)
    }

    @Test("Resposta inválida é rejeitada sem expor conteúdo", arguments: [
        "not json", "{}", "{\"error\":\"private detail\"}",
        "{\"five_hour\":{\"utilization\":5,\"resets_at\":\"invalid\"}}",
        "{\"five_hour\":{\"utilization\":\"5\"}}"
    ])
    func invalid(json: String) {
        #expect(throws: ClaudeAccountError.invalidResponse) {
            try ClaudeAccountPayload.snapshot(from: Data(json.utf8), at: now)
        }
    }

    @Test("Percentuais são limitados e reset passado não vira zero")
    func boundaries() throws {
        let data = Data("""
        {"five_hour":{"utilization":120,"resets_at":"2020-01-01T00:00:00Z"},
         "seven_day":{"utilization":-10,"resets_at":"2020-01-01T00:00:00Z"}}
        """.utf8)
        let snapshot = try ClaudeAccountPayload.snapshot(from: data, at: now)
        #expect(snapshot.fiveHour?.usedPercentage == 100)
        #expect(snapshot.fiveHour?.hasReset(at: now) == true)
        #expect(snapshot.sevenDay?.usedPercentage == 0)
    }

    @Test("Zero com reset null preserva 5h, semanal e persistência")
    func zeroWithoutReset() throws {
        let data = Data("""
        {"five_hour":{"utilization":0,"resets_at":null},
         "seven_day":{"utilization":24,"resets_at":"2027-01-20T01:59:59.713104+00:00"}}
        """.utf8)
        let snapshot = try ClaudeAccountPayload.snapshot(from: data, at: now)
        #expect(snapshot.fiveHour?.usedPercentage == 0)
        #expect(snapshot.fiveHour?.remainingPercentage == 100)
        #expect(snapshot.fiveHour?.resetsAt == nil)
        #expect(snapshot.fiveHour?.hasReset(at: now) == false)
        #expect(snapshot.sevenDay?.usedPercentage == 24)
        #expect(snapshot.sevenDay?.resetsAt != nil)
        #expect(try JSONDecoder().decode(UsageSnapshot.self, from: JSONEncoder().encode(snapshot)) == snapshot)
    }

    @Test("Erros HTTP e Retry-After são tipados", arguments: [401, 403, 429, 500, 302])
    func httpErrors(status: Int) async throws {
        let client = ClaudeAccountClient(credentials: { _, _ in "synthetic" }, transport: { request in
            let url = try #require(request.url)
            return (Data("private error".utf8), try #require(HTTPURLResponse(url: url,
                statusCode: status, httpVersion: nil, headerFields: ["Retry-After": "900"])))
        })
        let expected: ClaudeAccountError = status == 429 ? .rateLimited(until: now.addingTimeInterval(900))
            : [401, 403].contains(status) ? .unauthorized : .http(status)
        await #expect(throws: expected) { try await client.fetch(now: now) }
    }

    @Test("Retry-After aceita data HTTP e rejeita atrasos inválidos")
    func retryAfter() {
        #expect(ClaudeAccountClient.retryDate("Fri, 15 Jan 2027 10:00:00 GMT", now: now)
            == Date(timeIntervalSince1970: 1_800_007_200))
        for value in [nil, "NaN", "-5", "invalid"] as [String?] {
            #expect(ClaudeAccountClient.retryDate(value, now: now) == now.addingTimeInterval(300))
        }
    }

    @Test("Falha no login impede requisição")
    func noCredentialsNoNetwork() async {
        let client = ClaudeAccountClient(credentials: { _, _ in throw ClaudeAccountError.keychainDenied },
            transport: { _ in
                Issue.record("Não deveria enviar uma requisição sem login")
                throw ClaudeAccountError.connectionFailed
            })
        await #expect(throws: ClaudeAccountError.keychainDenied) { try await client.fetch(now: now) }
    }

    @Test("Credenciais exigem login válido, escopo e expiração")
    func credentialParsing() throws {
        let valid = Data("""
        {"claudeAiOauth":{"accessToken":"synthetic","expiresAt":1800003600000,"scopes":["user:profile"]}}
        """.utf8)
        #expect(try ClaudeOAuthCredentials.token(from: valid, now: now) == "synthetic")
        #expect(throws: ClaudeAccountError.expiredCredentials) {
            try ClaudeOAuthCredentials.token(from: valid, now: now.addingTimeInterval(4000))
        }
        #expect(throws: ClaudeAccountError.credentialsUnavailable) {
            try ClaudeOAuthCredentials.token(from: Data("{\"mcpOAuth\":{}}".utf8), now: now)
        }
        let noScope = Data("{\"claudeAiOauth\":{\"accessToken\":\"synthetic\",\"scopes\":[\"user:inference\"]}}".utf8)
        #expect(throws: ClaudeAccountError.missingScope) { try ClaudeOAuthCredentials.token(from: noScope, now: now) }
    }
}

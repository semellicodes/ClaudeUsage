import Foundation
import Security
import LocalAuthentication

/// Lê o login existente, sem copiar, renovar ou modificar credenciais do Claude Code.
public enum ClaudeOAuthCredentials {
    public static func accessToken(allowInteraction: Bool, now: Date) throws -> String {
        let context = LAContext()
        context.interactionNotAllowed = !allowInteraction
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            return try token(from: data, now: now)
        }
        // Uma recusa do Chaves não pode ser contornada por outra fonte.
        guard status == errSecItemNotFound else { throw ClaudeAccountError.keychainDenied }
        let file = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/.credentials.json")
        guard let data = try? Data(contentsOf: file) else { throw ClaudeAccountError.credentialsUnavailable }
        return try token(from: data, now: now)
    }

    static func token(from data: Data, now: Date) throws -> String {
        struct Document: Decodable {
            struct OAuth: Decodable {
                let accessToken: String
                let expiresAt: Double?
                let scopes: [String]?
            }
            let claudeAiOauth: OAuth?
        }
        guard let document = try? JSONDecoder().decode(Document.self, from: data),
              let oauth = document.claudeAiOauth,
              !oauth.accessToken.isEmpty else { throw ClaudeAccountError.credentialsUnavailable }
        if let expiration = oauth.expiresAt,
           !expiration.isFinite || expiration / 1000 <= now.timeIntervalSince1970 {
            throw ClaudeAccountError.expiredCredentials
        }
        if let scopes = oauth.scopes, !scopes.contains("user:profile") {
            throw ClaudeAccountError.missingScope
        }
        return oauth.accessToken
    }
}

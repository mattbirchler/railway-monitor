//
//  OpenRouterAPI.swift
//  Railway Monitor
//

import Foundation

/// Client for the OpenRouter REST API. Reads key usage and, when permitted, credit balance.
actor OpenRouterAPI {
    private let baseURL = URL(string: "https://openrouter.ai/api/v1")!
    private var token: String?

    func setToken(_ token: String) {
        self.token = token
    }

    func loadTokenFromKeychain() {
        self.token = KeychainService.retrieve(for: .openRouter)
    }

    var hasToken: Bool {
        !(token?.isEmpty ?? true)
    }

    private func authorization() throws -> String {
        guard let token, !token.isEmpty else { throw CloudAPIError.noToken }
        return "Bearer \(token)"
    }

    /// Fetches usage for the current key. Also serves as token validation.
    func fetchKeyInfo() async throws -> OpenRouterKeyInfo {
        let url = baseURL.appending(path: "key")
        let envelope: OpenRouterEnvelope<OpenRouterKeyInfo> = try await RESTClient.get(url, authorization: authorization())
        return envelope.data
    }

    /// Fetches account-wide credits. Requires a management key; returns `nil` otherwise.
    func fetchCreditsIfPermitted() async -> OpenRouterCredits? {
        let url = baseURL.appending(path: "credits")
        do {
            let envelope: OpenRouterEnvelope<OpenRouterCredits> = try await RESTClient.get(url, authorization: authorization())
            return envelope.data
        } catch {
            return nil
        }
    }

    /// Fetches key usage plus credits when the key allows it.
    func fetchAccount() async throws -> OpenRouterAccount {
        let key = try await fetchKeyInfo()
        let credits = await fetchCreditsIfPermitted()
        return OpenRouterAccount(key: key, credits: credits)
    }
}

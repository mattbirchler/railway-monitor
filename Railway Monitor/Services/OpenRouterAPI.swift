//
//  OpenRouterAPI.swift
//  Railway Monitor
//

import Foundation

/// Client for the OpenRouter REST API. Reads key usage and, when permitted, credit balance.
/// OpenRouter keys are scoped to a single workspace, so the key is passed per call
/// rather than stored on the client.
actor OpenRouterAPI {
    private let baseURL = URL(string: "https://openrouter.ai/api/v1")!

    private func authorization(_ key: String) throws -> String {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CloudAPIError.noToken }
        return "Bearer \(trimmed)"
    }

    /// Fetches usage for the given key. Also serves as key validation.
    func fetchKeyInfo(key: String) async throws -> OpenRouterKeyInfo {
        let url = baseURL.appending(path: "key")
        let envelope: OpenRouterEnvelope<OpenRouterKeyInfo> = try await RESTClient.get(url, authorization: authorization(key))
        return envelope.data
    }

    /// Fetches workspace-wide credits. Requires a management key; returns `nil` otherwise.
    func fetchCreditsIfPermitted(key: String) async -> OpenRouterCredits? {
        let url = baseURL.appending(path: "credits")
        do {
            let envelope: OpenRouterEnvelope<OpenRouterCredits> = try await RESTClient.get(url, authorization: try authorization(key))
            return envelope.data
        } catch {
            return nil
        }
    }

    /// Fetches key usage plus credits when the key allows it.
    func fetchAccount(key: String) async throws -> OpenRouterAccount {
        let info = try await fetchKeyInfo(key: key)
        let credits = await fetchCreditsIfPermitted(key: key)
        return OpenRouterAccount(key: info, credits: credits)
    }
}

//
//  OpenRouterModels.swift
//  Railway Monitor
//

import Foundation

// Decodable models for the OpenRouter REST API. All responses wrap their payload in `data`.

nonisolated struct OpenRouterEnvelope<T: Decodable & Sendable>: Decodable, Sendable {
    let data: T
}

/// Payload of `GET /api/v1/key`. Describes the key used to make the request.
/// All monetary values are in US dollars.
nonisolated struct OpenRouterKeyInfo: Decodable, Sendable {
    let label: String?
    let usage: Double
    let usageDaily: Double?
    let usageWeekly: Double?
    let usageMonthly: Double?
    let limit: Double?
    let limitRemaining: Double?
    let limitReset: String?
    let isFreeTier: Bool?

    enum CodingKeys: String, CodingKey {
        case label
        case usage
        case usageDaily = "usage_daily"
        case usageWeekly = "usage_weekly"
        case usageMonthly = "usage_monthly"
        case limit
        case limitRemaining = "limit_remaining"
        case limitReset = "limit_reset"
        case isFreeTier = "is_free_tier"
    }
}

/// Payload of `GET /api/v1/credits`. Only available to management keys.
nonisolated struct OpenRouterCredits: Decodable, Sendable {
    let totalCredits: Double
    let totalUsage: Double

    enum CodingKeys: String, CodingKey {
        case totalCredits = "total_credits"
        case totalUsage = "total_usage"
    }

    var remaining: Double { totalCredits - totalUsage }
}

/// Everything the app knows about an OpenRouter account after a refresh.
nonisolated struct OpenRouterAccount: Sendable {
    let key: OpenRouterKeyInfo
    /// `nil` when the key is not a management key.
    let credits: OpenRouterCredits?
}

// MARK: - Stored credentials

/// One OpenRouter API key. Keys are scoped to a workspace, so the user names each one.
nonisolated struct OpenRouterCredential: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var name: String
    var key: String
}

/// Persists the list of OpenRouter credentials as a single JSON blob in the Keychain.
nonisolated enum OpenRouterCredentialStore {
    private static let account = "openrouter-workspaces"

    /// Loads saved credentials. Migrates a single legacy key into the list on first run.
    static func load() -> [OpenRouterCredential] {
        if let data = KeychainService.retrieveData(account: account),
           let list = try? JSONDecoder().decode([OpenRouterCredential].self, from: data) {
            return list
        }

        // Migrate the single-key entry from earlier versions.
        if let legacy = KeychainService.retrieve(for: .openRouter), !legacy.isEmpty {
            let migrated = [OpenRouterCredential(id: UUID(), name: "Default", key: legacy)]
            save(migrated)
            KeychainService.delete(for: .openRouter)
            return migrated
        }

        return []
    }

    static func save(_ credentials: [OpenRouterCredential]) {
        if credentials.isEmpty {
            KeychainService.delete(account: account)
            return
        }
        guard let data = try? JSONEncoder().encode(credentials) else { return }
        KeychainService.saveData(data, account: account)
    }
}

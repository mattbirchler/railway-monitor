//
//  CloudService.swift
//  Railway Monitor
//

import Foundation

/// A cloud provider the app can monitor. Each case carries the static metadata
/// needed to connect, store credentials, and link back to the provider's dashboard.
nonisolated enum CloudService: String, CaseIterable, Identifiable, Sendable {
    case railway
    case digitalOcean
    case openRouter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .railway: return "Railway"
        case .digitalOcean: return "DigitalOcean"
        case .openRouter: return "OpenRouter"
        }
    }

    /// SF Symbol used to represent the service in lists and section headers.
    var symbolName: String {
        switch self {
        case .railway: return "train.side.front.car"
        case .digitalOcean: return "drop.fill"
        case .openRouter: return "arrow.triangle.branch"
        }
    }

    /// Keychain account name for the stored token. Railway keeps its original
    /// account name so existing installs stay signed in after upgrading.
    var keychainAccount: String {
        switch self {
        case .railway: return "railway-api-token"
        case .digitalOcean: return "digitalocean-api-token"
        case .openRouter: return "openrouter-api-key"
        }
    }

    /// What the credential is called in the provider's own UI.
    var credentialLabel: String {
        switch self {
        case .railway: return "API Token"
        case .digitalOcean: return "Personal Access Token"
        case .openRouter: return "API Key"
        }
    }

    var setupInstructions: String {
        switch self {
        case .railway:
            return "Enter your Railway API token to get started."
        case .digitalOcean:
            return "Enter a DigitalOcean personal access token. Read-only scope with billing access is enough."
        case .openRouter:
            return "Enter an OpenRouter API key. Keys are scoped to one workspace, so you can add one per workspace. A management key also shows that workspace's credit balance."
        }
    }

    /// Page where the user can create a credential.
    var tokenURL: URL {
        switch self {
        case .railway: return URL(string: "https://railway.com/account/tokens")!
        case .digitalOcean: return URL(string: "https://cloud.digitalocean.com/account/api/tokens")!
        case .openRouter: return URL(string: "https://openrouter.ai/settings/keys")!
        }
    }

    /// Page the dashboard link button opens.
    var dashboardURL: URL {
        switch self {
        case .railway: return URL(string: "https://railway.com/dashboard")!
        case .digitalOcean: return URL(string: "https://cloud.digitalocean.com/account/billing")!
        case .openRouter: return URL(string: "https://openrouter.ai/activity")!
        }
    }
}

//
//  KeychainService.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import Foundation
import Security

/// Thin wrapper around the macOS Keychain for storing and retrieving the Railway API token.
/// The token is stored as a generic password, accessible only while the device is unlocked.
nonisolated enum KeychainService {
    private static let service = "com.birchtree.Railway-Monitor"
    private static let account = "railway-api-token"

    /// Saves the token to Keychain, replacing any existing entry.
    nonisolated static func save(token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }

        // Delete existing item first
        delete()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Returns the stored token, or `nil` if none exists.
    nonisolated static func retrieve() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Removes the stored token. Returns `true` if deleted or if no token was stored.
    @discardableResult
    nonisolated static func delete() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

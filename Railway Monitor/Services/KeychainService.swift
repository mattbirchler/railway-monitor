//
//  KeychainService.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import Foundation
import Security

/// Thin wrapper around the macOS Keychain for storing one credential per cloud service.
/// Each token is stored as a generic password, accessible only while the device is unlocked.
nonisolated enum KeychainService {
    private static let service = "com.birchtree.Railway-Monitor"

    /// Saves the token for the given service, replacing any existing entry.
    @discardableResult
    nonisolated static func save(token: String, for cloudService: CloudService) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }

        // Delete existing item first
        delete(for: cloudService)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: cloudService.keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Returns the stored token for the given service, or `nil` if none exists.
    nonisolated static func retrieve(for cloudService: CloudService) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: cloudService.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Removes the stored token for the given service. Returns `true` if deleted or if none was stored.
    @discardableResult
    nonisolated static func delete(for cloudService: CloudService) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: cloudService.keychainAccount
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

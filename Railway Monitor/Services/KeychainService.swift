//
//  KeychainService.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import Foundation
import Security

/// Thin wrapper around the macOS Keychain. Stores one credential per cloud service,
/// plus arbitrary data blobs for services that hold more than one key.
/// Items are generic passwords, accessible only while the device is unlocked.
nonisolated enum KeychainService {
    private static let service = "com.birchtree.Railway-Monitor"

    // MARK: - Per-service tokens

    /// Saves the token for the given service, replacing any existing entry.
    @discardableResult
    nonisolated static func save(token: String, for cloudService: CloudService) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        return saveData(data, account: cloudService.keychainAccount)
    }

    /// Returns the stored token for the given service, or `nil` if none exists.
    nonisolated static func retrieve(for cloudService: CloudService) -> String? {
        guard let data = retrieveData(account: cloudService.keychainAccount) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Removes the stored token for the given service. Returns `true` if deleted or if none was stored.
    @discardableResult
    nonisolated static func delete(for cloudService: CloudService) -> Bool {
        delete(account: cloudService.keychainAccount)
    }

    // MARK: - Raw data

    @discardableResult
    nonisolated static func saveData(_ data: Data, account: String) -> Bool {
        // Delete existing item first
        delete(account: account)

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

    nonisolated static func retrieveData(account: String) -> Data? {
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
        return data
    }

    @discardableResult
    nonisolated static func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

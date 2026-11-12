// file: KeychainHelper.swift
// what: saves and reads small secrets (like the database key) in the ios keychain.
// story: us01

import Foundation
import Security

enum KeychainHelper {
    // every fitvault item in the keychain uses this service name
    static let service = "com.divineib.fitvault"

    // saves data for an account name. replaces anything already there.
    @discardableResult
    static func save(_ data: Data, account: String) -> Bool {
        delete(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            // only readable while the phone is unlocked, and never copied to backups or other devices
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // reads data for an account name, or nil if nothing is saved
    static func read(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    // removes the item for an account name
    static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // true if the saved item uses the "this device only, when unlocked" setting
    static func isDeviceOnly(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let attributes = result as? [String: Any],
              let accessible = attributes[kSecAttrAccessible as String] as? String
        else { return false }
        return accessible == (kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
    }
}

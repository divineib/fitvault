// file: DatabaseKey.swift
// what: makes the random database key on first launch and keeps it in the keychain.
// story: us01

import Foundation
import Security

enum DatabaseKeyError: Error {
    case randomFailed
    case keychainSaveFailed
}

enum DatabaseKey {
    // the keychain account name for the real app's key
    static let defaultAccount = "database-key"

    // 32 bytes = a 256-bit aes key
    static let keyLength = 32

    // returns the saved key, or makes a new random one the first time
    static func loadOrCreate(account: String = defaultAccount) throws -> Data {
        if let existing = KeychainHelper.read(account: account) {
            return existing
        }

        let newKey = try randomBytes(count: keyLength)
        guard KeychainHelper.save(newKey, account: account) else {
            throw DatabaseKeyError.keychainSaveFailed
        }
        return newKey
    }

    // asks ios for secure random bytes
    static func randomBytes(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        guard status == errSecSuccess else { throw DatabaseKeyError.randomFailed }
        return Data(bytes)
    }
}

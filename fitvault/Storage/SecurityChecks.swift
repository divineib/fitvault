// file: SecurityChecks.swift
// what: runs the checks shown on the security screen (encryption, keychain, pin hash).
// story: us01, us02

import Foundation

struct SecurityCheck: Identifiable {
    let id = UUID()
    let title: String
    let passed: Bool
}

enum SecurityChecks {
    // runs every check against the real app database
    static func run(database: Database, lock: LockManager) -> [SecurityCheck] {
        let path = database.path
        return [
            SecurityCheck(
                title: "database file is encrypted",
                passed: Database.fileLooksEncrypted(path: path)
            ),
            SecurityCheck(
                title: "database can't be opened without the key",
                passed: !Database.opensWithoutKey(path: path)
            ),
            SecurityCheck(
                title: "key is stored in the keychain",
                passed: KeychainHelper.read(account: DatabaseKey.defaultAccount) != nil
            ),
            SecurityCheck(
                title: "key stays on this device and needs it unlocked",
                passed: KeychainHelper.isDeviceOnly(account: DatabaseKey.defaultAccount)
            ),
            SecurityCheck(
                title: "pin is stored as a salted hash (pbkdf2)",
                passed: lock.pinIsStoredAsHash
            ),
        ]
    }
}

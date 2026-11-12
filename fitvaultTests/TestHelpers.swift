// file: TestHelpers.swift
// what: small helpers shared by the tests.

import Foundation
@testable import fitvault

enum TestHelpers {
    // a fresh file path in the temp folder, so tests never touch real data
    static func tempDatabasePath() -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).sqlite")
            .path
    }

    // a random 32-byte key for test databases
    static func randomKey() -> Data {
        try! DatabaseKey.randomBytes(count: 32)
    }

    // an encrypted test database with the app's tables already made
    static func makeDatabase() throws -> Database {
        let db = try Database(path: tempDatabasePath(), key: randomKey())
        try AppDatabase.createTables(in: db)
        return db
    }
}

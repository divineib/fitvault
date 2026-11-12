// file: DatabaseTests.swift
// what: tests that the database is encrypted and only opens with the right key.
// story: us01

import Foundation
import Testing
@testable import fitvault

struct DatabaseTests {

    @Test func savedDataLoadsAfterReopening() throws {
        let path = TestHelpers.tempDatabasePath()
        let key = TestHelpers.randomKey()

        // save something, then close the database
        var db: Database? = try Database(path: path, key: key)
        try AppDatabase.createTables(in: db!)
        SettingsStore(database: db!).set("sample", to: "hello")
        db?.close()
        db = nil

        // open it again with the same key and read it back
        let reopened = try Database(path: path, key: key)
        #expect(SettingsStore(database: reopened).string("sample") == "hello")
    }

    @Test func wrongKeyIsRejected() throws {
        let path = TestHelpers.tempDatabasePath()
        let db = try Database(path: path, key: TestHelpers.randomKey())
        try AppDatabase.createTables(in: db)
        db.close()

        #expect(throws: DatabaseError.wrongKey) {
            _ = try Database(path: path, key: TestHelpers.randomKey())
        }
    }

    @Test func fileIsNotReadableAsPlainSQLite() throws {
        let db = try TestHelpers.makeDatabase()
        SettingsStore(database: db).set("sample", to: "secret value")
        let path = db.path
        db.close()

        // the file must not start with "SQLite format 3"
        #expect(Database.fileLooksEncrypted(path: path))
        // and normal sqlite with no key must fail to read it
        #expect(Database.opensWithoutKey(path: path) == false)
        // the saved text must not appear anywhere in the raw file
        let raw = try Data(contentsOf: URL(fileURLWithPath: path))
        #expect(raw.range(of: Data("secret value".utf8)) == nil)
    }

    @Test func sqlcipherIsInUse() throws {
        let db = try TestHelpers.makeDatabase()
        #expect(db.cipherVersion() != nil)
    }

    @Test func settingsCanBeUpdatedAndRemoved() throws {
        let settings = SettingsStore(database: try TestHelpers.makeDatabase())
        settings.set("count", to: "1")
        settings.set("count", to: "2")
        #expect(settings.int("count") == 2)
        settings.remove("count")
        #expect(settings.string("count") == nil)
    }
}

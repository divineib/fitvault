// file: AppDatabase.swift
// what: knows where the app's database file lives and creates its tables.
// story: us01

import Foundation

enum AppDatabase {
    // the database file inside the app's private "application support" folder
    static func fileURL() throws -> URL {
        let folder = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return folder.appendingPathComponent("fitvault.sqlite")
    }

    // opens the real app database with the key from the keychain
    static func openDefault() throws -> Database {
        let key = try DatabaseKey.loadOrCreate()
        let url = try fileURL()
        let db = try Database(path: url.path, key: key)

        // extra apple file protection on top of sqlcipher
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )

        try createTables(in: db)
        return db
    }

    // makes the tables if they do not exist yet
    static func createTables(in db: Database) throws {
        // simple name/value pairs for app settings
        try db.execute("""
            CREATE TABLE IF NOT EXISTS settings (
                name TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );
            """)
    }
}

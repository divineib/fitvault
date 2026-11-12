// file: AppDatabase.swift
// what: knows where the app's database file lives and creates its tables.
// story: us01, us03

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

        // us03: a workout has exercises, an exercise has sets.
        // "on delete cascade" means deleting a workout also deletes its exercises and sets.
        try db.execute("""
            CREATE TABLE IF NOT EXISTS workouts (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                date REAL NOT NULL
            );
            """)
        try db.execute("""
            CREATE TABLE IF NOT EXISTS exercises (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                workout_id TEXT NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
                position INTEGER NOT NULL,
                name TEXT NOT NULL
            );
            """)
        try db.execute("""
            CREATE TABLE IF NOT EXISTS workout_sets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                exercise_id INTEGER NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
                position INTEGER NOT NULL,
                reps INTEGER NOT NULL,
                weight_lbs REAL NOT NULL
            );
            """)
    }
}

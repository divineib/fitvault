// file: SettingsStore.swift
// what: reads and writes simple name/value settings in the encrypted database.
// story: us01

import Foundation

struct SettingsStore {
    let database: Database

    // reads a setting as text, or nil if it was never saved
    func string(_ name: String) -> String? {
        let rows = try? database.query("SELECT value FROM settings WHERE name = ?;", [.text(name)])
        return rows?.first?.text("value")
    }

    // reads a setting as a whole number
    func int(_ name: String) -> Int? {
        string(name).flatMap { Int($0) }
    }

    // saves a setting, replacing the old value
    func set(_ name: String, to value: String) {
        try? database.execute(
            "INSERT OR REPLACE INTO settings (name, value) VALUES (?, ?);",
            [.text(name), .text(value)]
        )
    }

    // removes a setting
    func remove(_ name: String) {
        try? database.execute("DELETE FROM settings WHERE name = ?;", [.text(name)])
    }
}

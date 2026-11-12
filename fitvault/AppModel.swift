// file: AppModel.swift
// what: holds the open database and app-wide info that screens need.
// story: us01

import Foundation

final class AppModel: ObservableObject {
    // the open, encrypted database (nil only if opening failed)
    let database: Database?

    // shown on screen if the database could not be opened
    let startupError: String?

    // how many times the vault has been opened. proves data survives restarts.
    @Published var launchCount: Int = 0

    init() {
        do {
            let db = try AppDatabase.openDefault()
            database = db
            startupError = nil

            // count this launch and save it in the encrypted database
            let settings = SettingsStore(database: db)
            let count = (settings.int("launch_count") ?? 0) + 1
            settings.set("launch_count", to: String(count))
            launchCount = count
        } catch {
            database = nil
            startupError = "could not open the encrypted database: \(error)"
        }
    }
}

// file: AppModel.swift
// what: holds the open database, the app lock, and app-wide info that screens need.
// story: us01, us02

import Foundation

final class AppModel: ObservableObject {
    // the open, encrypted database (nil only if opening failed)
    let database: Database?

    // the app lock (nil only if the database failed to open)
    let lock: LockManager?

    // shown on screen if the database could not be opened
    let startupError: String?

    // how many times the vault has been opened. proves data survives restarts.
    @Published var launchCount: Int = 0

    init() {
        do {
            let db = try AppDatabase.openDefault()
            let settings = SettingsStore(database: db)
            database = db
            lock = LockManager(settings: settings)
            startupError = nil

            // count this launch and save it in the encrypted database
            let count = (settings.int("launch_count") ?? 0) + 1
            settings.set("launch_count", to: String(count))
            launchCount = count
        } catch {
            database = nil
            lock = nil
            startupError = "could not open the encrypted database: \(error)"
        }
    }
}

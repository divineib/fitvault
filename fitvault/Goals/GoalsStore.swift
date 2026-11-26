// file: GoalsStore.swift
// what: saves and loads the daily goals in the encrypted database (in the settings table).
// story: us06

import Foundation

final class GoalsStore: ObservableObject {
    // the current goals
    @Published private(set) var goals = DailyGoals()

    private let settings: SettingsStore

    // names used in the settings table
    private enum Keys {
        static let calories = "goal_calories"
        static let protein = "goal_protein_grams"
        static let sleep = "goal_sleep_hours"
    }

    init(settings: SettingsStore) {
        self.settings = settings
        goals = DailyGoals(
            calories: settings.int(Keys.calories),
            proteinGrams: settings.int(Keys.protein),
            sleepHours: settings.string(Keys.sleep).flatMap(Double.init)
        )
    }

    // saves new goals. a nil goal is removed from the database.
    func save(_ newGoals: DailyGoals) {
        store(newGoals.calories.map(String.init), as: Keys.calories)
        store(newGoals.proteinGrams.map(String.init), as: Keys.protein)
        store(newGoals.sleepHours.map { String($0) }, as: Keys.sleep)
        goals = newGoals
    }

    private func store(_ value: String?, as name: String) {
        if let value {
            settings.set(name, to: value)
        } else {
            settings.remove(name)
        }
    }
}

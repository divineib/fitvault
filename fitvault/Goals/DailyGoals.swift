// file: DailyGoals.swift
// what: the user's daily goals (calories, protein, sleep), the form used to edit them,
//       and the rules for what counts as a valid goal.
// story: us06

import Foundation

// the saved goals. nil means "no goal set yet".
struct DailyGoals: Equatable {
    var calories: Int?
    var proteinGrams: Int?
    var sleepHours: Double?
}

// the editable version used by the goals screen. numbers stay as text while typing.
struct GoalsForm: Equatable {
    // limits that catch typos (like 25000 instead of 2500)
    static let maxCalories = 10_000
    static let maxProteinGrams = 1_000
    static let maxSleepHours = 24.0

    var calories = ""
    var protein = ""
    var sleep = ""

    // a blank form
    init() {}

    // a form filled in from saved goals
    init(goals: DailyGoals) {
        calories = goals.calories.map(String.init) ?? ""
        protein = goals.proteinGrams.map(String.init) ?? ""
        sleep = goals.sleepHours.map { $0.formatted(.number.precision(.fractionLength(0...1)).grouping(.never)) } ?? ""
    }

    // checks every box and builds the goals to save. throws a FormProblem if something is wrong.
    // a blank box means "no goal" and is allowed.
    func makeGoals() throws -> DailyGoals {
        DailyGoals(
            calories: try wholeNumber(calories, name: "calories", max: GoalsForm.maxCalories),
            proteinGrams: try wholeNumber(protein, name: "protein", max: GoalsForm.maxProteinGrams),
            sleepHours: try hours(sleep)
        )
    }

    // a whole number from 1 to max, or nil if blank
    private func wholeNumber(_ text: String, name: String, max: Int) throws -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        guard let value = Int(trimmed), value >= 1, value <= max else {
            throw FormProblem(message: "\(name) goal must be a whole number from 1 to \(max).")
        }
        return value
    }

    // hours of sleep above 0 and up to 24 (like 7.5), or nil if blank
    private func hours(_ text: String) throws -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if trimmed.isEmpty { return nil }
        guard let value = Double(trimmed), value > 0, value <= GoalsForm.maxSleepHours else {
            throw FormProblem(message: "sleep goal must be more than 0 and up to 24 hours.")
        }
        return value
    }
}

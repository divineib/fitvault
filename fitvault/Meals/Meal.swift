// file: Meal.swift
// what: a saved meal, the form used to add one, the rules for valid numbers,
//       and the daily totals shown at the top of each day.
// story: us04

import Foundation

// one saved meal
struct Meal: Identifiable, Equatable {
    // a uuid string, also used as the id in the database
    var id: String = UUID().uuidString
    var name: String
    var date: Date
    var calories: Int
    var proteinGrams: Double
    // optional, nil means not entered
    var carbsGrams: Double?
    var fatGrams: Double?
}

// the totals for one day
struct DailyTotals: Equatable {
    var calories = 0
    var proteinGrams = 0.0
    var carbsGrams = 0.0
    var fatGrams = 0.0

    // adds up every meal (blank carbs or fat count as 0)
    init(meals: [Meal]) {
        for meal in meals {
            calories += meal.calories
            proteinGrams += meal.proteinGrams
            carbsGrams += meal.carbsGrams ?? 0
            fatGrams += meal.fatGrams ?? 0
        }
    }
}

// meals that share a day, for the list sections
struct MealDay: Identifiable, Equatable {
    var day: Date            // the start of the day
    var meals: [Meal]        // newest first
    var id: Date { day }
    var totals: DailyTotals { DailyTotals(meals: meals) }

    // groups meals by calendar day, newest day first and newest meal first
    static func group(_ meals: [Meal], calendar: Calendar = .current) -> [MealDay] {
        let byDay = Dictionary(grouping: meals) { calendar.startOfDay(for: $0.date) }
        return byDay
            .map { MealDay(day: $0.key, meals: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }
}

// the editable version used by the add meal screen. numbers stay as text while typing.
struct MealForm: Equatable {
    // limits that catch typos
    static let maxCalories = 10_000
    static let maxGrams = 1_000.0

    var name = ""
    var calories = ""
    var protein = ""
    var carbs = ""
    var fat = ""

    // checks every box and builds the meal. throws a FormProblem if something is wrong.
    func makeMeal(date: Date = Date()) throws -> Meal {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        return Meal(
            name: trimmedName.isEmpty ? "meal" : trimmedName,
            date: date,
            calories: try requiredCalories(),
            proteinGrams: try grams(protein, name: "protein", required: true) ?? 0,
            carbsGrams: try grams(carbs, name: "carbs", required: false),
            fatGrams: try grams(fat, name: "fat", required: false)
        )
    }

    // calories: required, a whole number from 0 to 10000 (0 is allowed, like black coffee)
    private func requiredCalories() throws -> Int {
        let trimmed = calories.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            throw FormProblem(message: "enter the calories for this meal.")
        }
        guard let value = Int(trimmed) else {
            throw FormProblem(message: "calories must be a whole number, like 450.")
        }
        guard value >= 0 else {
            throw FormProblem(message: "calories can't be negative.")
        }
        guard value <= MealForm.maxCalories else {
            throw FormProblem(message: "calories must be \(MealForm.maxCalories) or less for one meal.")
        }
        return value
    }

    // grams from 0 to 1000 (decimals and a comma are allowed). nil if blank and not required.
    private func grams(_ text: String, name: String, required: Bool) throws -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if trimmed.isEmpty {
            if required { throw FormProblem(message: "enter the \(name) for this meal (0 is fine).") }
            return nil
        }
        guard let value = Double(trimmed), value >= 0, value <= MealForm.maxGrams else {
            throw FormProblem(message: "\(name) must be a number from 0 to \(Int(MealForm.maxGrams)) grams.")
        }
        return value
    }
}

enum GramsText {
    // shows 32 as "32" and 12.5 as "12.5"
    static func format(_ grams: Double) -> String {
        grams.formatted(.number.precision(.fractionLength(0...1)).grouping(.never))
    }
}

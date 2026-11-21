// file: MealStore.swift
// what: saves, loads, and deletes meals in the encrypted database.
// story: us04

import Foundation

final class MealStore: ObservableObject {
    // every saved meal, grouped by day, newest first
    @Published private(set) var days: [MealDay] = []

    private let database: Database

    init(database: Database) {
        self.database = database
        reload()
    }

    // reads all meals from the database
    func reload() {
        let rows = (try? database.query("SELECT id, name, date, calories, protein_g, carbs_g, fat_g FROM meals;")) ?? []
        let meals = rows.map { row in
            Meal(
                id: row.text("id") ?? "",
                name: row.text("name") ?? "",
                date: Date(timeIntervalSince1970: row.double("date") ?? 0),
                calories: row.int("calories") ?? 0,
                proteinGrams: row.double("protein_g") ?? 0,
                carbsGrams: row.double("carbs_g"),
                fatGrams: row.double("fat_g")
            )
        }
        days = MealDay.group(meals)
    }

    // the totals for one day (today unless another day is given)
    func totals(on day: Date = Date(), calendar: Calendar = .current) -> DailyTotals {
        let start = calendar.startOfDay(for: day)
        return days.first { $0.day == start }?.totals ?? DailyTotals(meals: [])
    }

    // saves a meal and refreshes the list, so totals update right away
    func save(_ meal: Meal) throws {
        try database.execute(
            "INSERT OR REPLACE INTO meals (id, name, date, calories, protein_g, carbs_g, fat_g) VALUES (?, ?, ?, ?, ?, ?, ?);",
            [
                .text(meal.id),
                .text(meal.name),
                .double(meal.date.timeIntervalSince1970),
                .int(Int64(meal.calories)),
                .double(meal.proteinGrams),
                meal.carbsGrams.map { .double($0) } ?? .null,
                meal.fatGrams.map { .double($0) } ?? .null,
            ]
        )
        reload()
    }

    func delete(_ meal: Meal) throws {
        try database.execute("DELETE FROM meals WHERE id = ?;", [.text(meal.id)])
        reload()
    }
}

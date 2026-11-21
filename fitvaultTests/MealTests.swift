// file: MealTests.swift
// what: tests meal rules (calories and protein required, no negatives), daily totals,
//       grouping by day, and saving/loading/deleting meals in the database.
// story: us04

import Foundation
import Testing
@testable import fitvault

struct MealTests {
    let noon = Date(timeIntervalSince1970: 1_800_000_000)   // a fixed time for repeatable tests

    func filledForm() -> MealForm {
        var form = MealForm()
        form.name = "chicken and rice"
        form.calories = "650"
        form.protein = "45"
        return form
    }

    func meal(_ name: String, calories: Int, protein: Double, at date: Date) -> Meal {
        Meal(name: name, date: date, calories: calories, proteinGrams: protein)
    }

    // MARK: rules

    @Test func caloriesAndProteinAreEnough() throws {
        let meal = try filledForm().makeMeal(date: noon)
        #expect(meal.calories == 650)
        #expect(meal.proteinGrams == 45)
        #expect(meal.carbsGrams == nil)
        #expect(meal.fatGrams == nil)
    }

    @Test func carbsAndFatAreSavedWhenGiven() throws {
        var form = filledForm()
        form.carbs = "70.5"
        form.fat = "12,5"
        let meal = try form.makeMeal(date: noon)
        #expect(meal.carbsGrams == 70.5)
        #expect(meal.fatGrams == 12.5)
    }

    @Test func blankCaloriesAreRejected() {
        var form = filledForm()
        form.calories = ""
        #expect(throws: FormProblem(message: "enter the calories for this meal.")) { try form.makeMeal() }
    }

    @Test func negativeCaloriesAreRejected() {
        var form = filledForm()
        form.calories = "-200"
        #expect(throws: FormProblem(message: "calories can't be negative.")) { try form.makeMeal() }
    }

    @Test func otherBadCaloriesAreRejected() {
        for bad in ["abc", "450.5", "10001"] {
            var form = filledForm()
            form.calories = bad
            #expect(throws: FormProblem.self) { try form.makeMeal() }
        }
    }

    @Test func zeroCaloriesIsAllowed() throws {
        var form = filledForm()
        form.calories = "0"
        form.protein = "0"
        #expect(try form.makeMeal().calories == 0)
    }

    @Test func proteinIsRequired() {
        var form = filledForm()
        form.protein = ""
        #expect(throws: FormProblem(message: "enter the protein for this meal (0 is fine).")) { try form.makeMeal() }
    }

    @Test func badGramsAreRejected() {
        for field in ["protein", "carbs", "fat"] {
            for bad in ["-1", "lots", "1001"] {
                var form = filledForm()
                switch field {
                case "protein": form.protein = bad
                case "carbs": form.carbs = bad
                default: form.fat = bad
                }
                #expect(throws: FormProblem.self) { try form.makeMeal() }
            }
        }
    }

    @Test func blankNameBecomesMeal() throws {
        var form = filledForm()
        form.name = "  "
        #expect(try form.makeMeal().name == "meal")
    }

    // MARK: totals and grouping

    @Test func dailyTotalsAddUp() {
        var a = meal("breakfast", calories: 400, protein: 30, at: noon)
        a.carbsGrams = 50
        let b = meal("lunch", calories: 650, protein: 45.5, at: noon)
        let totals = DailyTotals(meals: [a, b])
        #expect(totals.calories == 1050)
        #expect(totals.proteinGrams == 75.5)
        #expect(totals.carbsGrams == 50)
        #expect(totals.fatGrams == 0)
    }

    @Test func mealsGroupByDayNewestFirst() {
        let yesterday = noon.addingTimeInterval(-86_400)
        let days = MealDay.group([
            meal("old dinner", calories: 700, protein: 40, at: yesterday),
            meal("breakfast", calories: 400, protein: 30, at: noon.addingTimeInterval(-3600)),
            meal("lunch", calories: 650, protein: 45, at: noon),
        ])
        #expect(days.count == 2)
        #expect(days[0].meals.map(\.name) == ["lunch", "breakfast"])
        #expect(days[0].totals.calories == 1050)
        #expect(days[1].meals.map(\.name) == ["old dinner"])
    }

    @Test func totalsTextShowsGoalsWhenSet() {
        let totals = DailyTotals(meals: [meal("lunch", calories: 650, protein: 45, at: noon)])
        #expect(TotalsText.summary(totals, goals: DailyGoals()) == "650 kcal · 45 g protein")
        #expect(TotalsText.summary(totals, goals: DailyGoals(calories: 2200, proteinGrams: 180))
                == "650 / 2200 kcal · 45 / 180 g protein")
    }

    // MARK: database

    @Test func totalsUpdateRightAfterSaving() throws {
        let store = MealStore(database: try TestHelpers.makeDatabase())
        #expect(store.totals(on: noon).calories == 0)

        try store.save(meal("breakfast", calories: 400, protein: 30, at: noon))
        #expect(store.totals(on: noon).calories == 400)

        try store.save(meal("lunch", calories: 650, protein: 45, at: noon))
        #expect(store.totals(on: noon).calories == 1050)
        #expect(store.totals(on: noon).proteinGrams == 75)
    }

    @Test func mealsLoadAfterReopening() throws {
        let path = TestHelpers.tempDatabasePath()
        let key = TestHelpers.randomKey()

        var db: Database? = try Database(path: path, key: key)
        try AppDatabase.createTables(in: db!)
        var saved = meal("lunch", calories: 650, protein: 45, at: noon)
        saved.fatGrams = 12.5
        try MealStore(database: db!).save(saved)
        db?.close()
        db = nil

        let store = MealStore(database: try Database(path: path, key: key))
        #expect(store.days.first?.meals.first == saved)
    }

    @Test func deleteRemovesTheMeal() throws {
        let store = MealStore(database: try TestHelpers.makeDatabase())
        let lunch = meal("lunch", calories: 650, protein: 45, at: noon)
        try store.save(lunch)
        try store.delete(lunch)
        #expect(store.days.isEmpty)
    }
}

// file: GoalsTests.swift
// what: tests daily goal rules (positive numbers only) and that goals stay saved after a restart.
// story: us06

import Foundation
import Testing
@testable import fitvault

struct GoalsTests {

    // MARK: rules

    @Test func validGoalsAreAccepted() throws {
        var form = GoalsForm()
        form.calories = "2400"
        form.protein = "180"
        form.sleep = "7.5"
        #expect(try form.makeGoals() == DailyGoals(calories: 2400, proteinGrams: 180, sleepHours: 7.5))
    }

    @Test func blankMeansNoGoal() throws {
        var form = GoalsForm()
        form.protein = "150"
        #expect(try form.makeGoals() == DailyGoals(calories: nil, proteinGrams: 150, sleepHours: nil))
    }

    @Test func commaWorksForSleep() throws {
        var form = GoalsForm()
        form.sleep = "8,5"
        #expect(try form.makeGoals().sleepHours == 8.5)
    }

    @Test func caloriesMustBePositiveWholeNumbers() {
        for bad in ["0", "-100", "abc", "2400.5", "10001"] {
            var form = GoalsForm()
            form.calories = bad
            #expect(throws: FormProblem.self) { try form.makeGoals() }
        }
    }

    @Test func proteinMustBePositiveWholeNumbers() {
        for bad in ["0", "-5", "lots", "1001"] {
            var form = GoalsForm()
            form.protein = bad
            #expect(throws: FormProblem.self) { try form.makeGoals() }
        }
    }

    @Test func sleepMustBeMoreThanZeroAndAtMost24() {
        for bad in ["0", "-1", "25", "zzz"] {
            var form = GoalsForm()
            form.sleep = bad
            #expect(throws: FormProblem.self) { try form.makeGoals() }
        }
    }

    @Test func errorMessageIsClear() {
        var form = GoalsForm()
        form.calories = "-100"
        #expect(throws: FormProblem(message: "calories goal must be a whole number from 1 to 10000.")) {
            try form.makeGoals()
        }
    }

    @Test func formRoundTrip() throws {
        let goals = DailyGoals(calories: 2200, proteinGrams: 160, sleepHours: 8)
        #expect(try GoalsForm(goals: goals).makeGoals() == goals)
    }

    // MARK: saving

    @Test func goalsStaySavedAfterRestart() throws {
        let settings = SettingsStore(database: try TestHelpers.makeDatabase())
        GoalsStore(settings: settings).save(DailyGoals(calories: 2400, proteinGrams: 180, sleepHours: 7.5))

        // a new store on the same database = the app opening again
        #expect(GoalsStore(settings: settings).goals == DailyGoals(calories: 2400, proteinGrams: 180, sleepHours: 7.5))
    }

    @Test func goalsCanBeChangedAndCleared() throws {
        let settings = SettingsStore(database: try TestHelpers.makeDatabase())
        let store = GoalsStore(settings: settings)
        store.save(DailyGoals(calories: 2400, proteinGrams: 180, sleepHours: 8))
        store.save(DailyGoals(calories: 2000, proteinGrams: nil, sleepHours: 8))

        let reopened = GoalsStore(settings: settings)
        #expect(reopened.goals.calories == 2000)
        #expect(reopened.goals.proteinGrams == nil)
    }

    @Test func summaryText() {
        #expect(GoalsSummary.text(for: DailyGoals()) == "not set")
        #expect(GoalsSummary.text(for: DailyGoals(calories: 2400, proteinGrams: 180, sleepHours: 7.5)) == "2400 kcal · 180 g · 7.5 h")
    }
}

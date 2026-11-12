// file: WorkoutTests.swift
// what: tests workout validation, "add set" copying, sorting, and saving/editing/deleting in the database.
// story: us03

import Foundation
import Testing
@testable import fitvault

struct WorkoutTests {

    // MARK: helpers

    // a form with one exercise and one set already filled in
    func filledForm(name: String = "push day") -> WorkoutForm {
        var form = WorkoutForm()
        form.name = name
        form.exercises[0].name = "bench press"
        form.exercises[0].sets[0] = SetForm(reps: "8", weight: "135")
        return form
    }

    func sample(_ name: String, daysAgo: Double) -> Workout {
        Workout(
            name: name,
            date: Date(timeIntervalSince1970: 1_800_000_000 - daysAgo * 86_400),
            exercises: [Exercise(name: "squat", sets: [WorkoutSet(reps: 5, weight: 225)])]
        )
    }

    // MARK: add set

    @Test func addSetCopiesThePreviousSet() {
        var exercise = ExerciseForm()
        exercise.sets[0] = SetForm(reps: "10", weight: "95")
        exercise.addSet()

        #expect(exercise.sets.count == 2)
        #expect(exercise.sets[1].reps == "10")
        #expect(exercise.sets[1].weight == "95")
        // it is a new row, not the same one
        #expect(exercise.sets[1].id != exercise.sets[0].id)
    }

    // MARK: validation

    @Test func fiveExerciseWorkoutSaves() throws {
        var form = WorkoutForm()
        form.exercises = []
        for name in ["bench press", "overhead press", "incline press", "dips", "triceps pushdown"] {
            var exercise = ExerciseForm(name: name)
            exercise.sets[0] = SetForm(reps: "10", weight: "100")
            exercise.addSet()
            exercise.addSet()
            form.exercises.append(exercise)
        }

        let workout = try form.makeWorkout()
        #expect(workout.exercises.count == 5)
        #expect(workout.setCount == 15)
        #expect(workout.exercises[4].sets[2] == WorkoutSet(reps: 10, weight: 100))
    }

    @Test func eachSetKeepsRepsAndWeight() throws {
        var form = filledForm()
        form.exercises[0].sets.append(SetForm(reps: "6", weight: "142.5"))
        let workout = try form.makeWorkout()
        #expect(workout.exercises[0].sets == [
            WorkoutSet(reps: 8, weight: 135),
            WorkoutSet(reps: 6, weight: 142.5),
        ])
    }

    @Test func blankNameBecomesWorkout() throws {
        let workout = try filledForm(name: "  ").makeWorkout()
        #expect(workout.name == "workout")
    }

    @Test func blankWeightMeansBodyweight() throws {
        var form = filledForm()
        form.exercises[0].sets[0].weight = ""
        #expect(try form.makeWorkout().exercises[0].sets[0].weight == 0)
    }

    @Test func commaWorksAsDecimalPoint() throws {
        var form = filledForm()
        form.exercises[0].sets[0].weight = "52,5"
        #expect(try form.makeWorkout().exercises[0].sets[0].weight == 52.5)
    }

    @Test func untouchedExerciseIsIgnored() throws {
        var form = filledForm()
        form.addExercise()   // left blank
        #expect(try form.makeWorkout().exercises.count == 1)
    }

    @Test func emptyWorkoutIsRejected() {
        #expect(throws: FormProblem(message: "add at least one exercise.")) {
            try WorkoutForm().makeWorkout()
        }
    }

    @Test func exerciseNeedsAName() {
        var form = filledForm()
        form.exercises[0].name = ""
        #expect(throws: FormProblem(message: "exercise 1 needs a name.")) {
            try form.makeWorkout()
        }
    }

    @Test func badRepsAreRejected() {
        for bad in ["", "0", "abc", "2.5", "1000"] {
            var form = filledForm()
            form.exercises[0].sets[0].reps = bad
            #expect(throws: FormProblem.self) { try form.makeWorkout() }
        }
    }

    @Test func badWeightsAreRejected() {
        for bad in ["-5", "abc", "2001"] {
            var form = filledForm()
            form.exercises[0].sets[0].weight = bad
            #expect(throws: FormProblem.self) { try form.makeWorkout() }
        }
    }

    @Test func editingKeepsTheSameId() throws {
        let original = try filledForm().makeWorkout()
        var form = WorkoutForm(workout: original)
        form.exercises[0].sets[0].reps = "12"

        let edited = try form.makeWorkout()
        #expect(edited.id == original.id)
        #expect(edited.exercises[0].sets[0].reps == 12)
    }

    @Test func formRoundTripMatchesOriginal() throws {
        let original = Workout(
            name: "legs",
            date: Date(timeIntervalSince1970: 1_800_000_000),
            exercises: [Exercise(name: "squat", sets: [WorkoutSet(reps: 5, weight: 227.5)])]
        )
        #expect(try WorkoutForm(workout: original).makeWorkout() == original)
    }

    // MARK: sorting

    @Test func historyIsNewestFirst() {
        let sorted = WorkoutSorting.newestFirst([
            sample("old", daysAgo: 10),
            sample("newest", daysAgo: 0),
            sample("middle", daysAgo: 3),
        ])
        #expect(sorted.map(\.name) == ["newest", "middle", "old"])
    }

    // MARK: database

    @Test func saveAndLoadAfterReopen() throws {
        let path = TestHelpers.tempDatabasePath()
        let key = TestHelpers.randomKey()

        var db: Database? = try Database(path: path, key: key)
        try AppDatabase.createTables(in: db!)
        try WorkoutStore(database: db!).save(sample("legs", daysAgo: 1))
        db?.close()
        db = nil

        let reopened = try Database(path: path, key: key)
        let store = WorkoutStore(database: reopened)
        #expect(store.workouts.count == 1)
        #expect(store.workouts[0].exercises[0].sets[0] == WorkoutSet(reps: 5, weight: 225))
    }

    @Test func storeListsNewestFirst() throws {
        let store = WorkoutStore(database: try TestHelpers.makeDatabase())
        try store.save(sample("old", daysAgo: 5))
        try store.save(sample("new", daysAgo: 0))
        try store.save(sample("middle", daysAgo: 2))
        #expect(store.workouts.map(\.name) == ["new", "middle", "old"])
    }

    @Test func editReplacesExercises() throws {
        let store = WorkoutStore(database: try TestHelpers.makeDatabase())
        var workout = sample("legs", daysAgo: 0)
        try store.save(workout)

        workout.name = "leg day"
        workout.exercises.append(Exercise(name: "lunge", sets: [WorkoutSet(reps: 10, weight: 40)]))
        try store.save(workout)

        #expect(store.workouts.count == 1)
        #expect(store.workouts[0].name == "leg day")
        #expect(store.workouts[0].exercises.map(\.name) == ["squat", "lunge"])
    }

    @Test func deleteRemovesWorkoutAndItsRows() throws {
        let db = try TestHelpers.makeDatabase()
        let store = WorkoutStore(database: db)
        let workout = sample("legs", daysAgo: 0)
        try store.save(workout)
        try store.delete(workout)

        #expect(store.workouts.isEmpty)
        // no leftover exercises or sets
        #expect(try db.query("SELECT count(*) AS n FROM exercises;").first?.int("n") == 0)
        #expect(try db.query("SELECT count(*) AS n FROM workout_sets;").first?.int("n") == 0)
    }

    @Test func weightText() {
        #expect(WeightText.format(135) == "135")
        #expect(WeightText.format(52.5) == "52.5")
        #expect(WeightText.format(1000) == "1000")
    }
}

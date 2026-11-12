// file: Workout.swift
// what: the saved workout data (a workout has exercises, an exercise has sets)
//       and the rule for sorting history newest first.
// story: us03

import Foundation

// one set: how many reps and how heavy
struct WorkoutSet: Equatable {
    var reps: Int
    // pounds for now. kilograms come later (us10).
    var weight: Double
}

// one exercise, like "bench press", with its sets in order
struct Exercise: Equatable {
    var name: String
    var sets: [WorkoutSet]
}

// one workout session
struct Workout: Identifiable, Equatable {
    // a uuid string, also used as the id in the database
    var id: String = UUID().uuidString
    var name: String
    var date: Date
    var exercises: [Exercise]

    // total sets across all exercises (shown in the history list)
    var setCount: Int {
        exercises.reduce(0) { total, exercise in total + exercise.sets.count }
    }
}

enum WorkoutSorting {
    // newest date first. if two have the same date, sort by name so the order never jumps around.
    static func newestFirst(_ workouts: [Workout]) -> [Workout] {
        workouts.sorted { a, b in
            if a.date != b.date { return a.date > b.date }
            return a.name < b.name
        }
    }
}

enum WeightText {
    // shows 135 as "135" and 52.5 as "52.5" (no commas, so it can go back into a text field)
    static func format(_ weight: Double) -> String {
        weight.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }
}

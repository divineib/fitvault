// file: DeleteConfirmation.swift
// what: the words shown when asking "are you sure?" before a workout is deleted.
//       used by both the history list (swipe) and the workout editor (button).
// story: us17

import Foundation

enum DeleteConfirmation {
    static let deleteButton = "delete"
    static let cancelButton = "cancel"

    // the alert title, with the workout's name so it's clear which one goes
    static func title(for workout: Workout) -> String {
        "delete \"\(workout.name)\"?"
    }

    // the alert message, saying what else goes with it
    static func message(for workout: Workout) -> String {
        let exercises = workout.exercises.count
        let sets = workout.setCount
        let exerciseWord = exercises == 1 ? "exercise" : "exercises"
        let setWord = sets == 1 ? "set" : "sets"
        return "its \(exercises) \(exerciseWord) and \(sets) \(setWord) will be deleted too. this can't be undone."
    }
}

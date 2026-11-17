// file: DeleteConfirmationTests.swift
// what: tests the words in the "are you sure?" alert before deleting a workout.
// story: us17

import Foundation
import Testing
@testable import fitvault

struct DeleteConfirmationTests {

    func workout(exercises: Int, setsEach: Int) -> Workout {
        Workout(
            name: "sample leg day",
            date: Date(timeIntervalSince1970: 1_800_000_000),
            exercises: (0..<exercises).map { n in
                Exercise(name: "exercise \(n)", sets: Array(repeating: WorkoutSet(reps: 5, weight: 100), count: setsEach))
            }
        )
    }

    @Test func titleNamesTheWorkout() {
        #expect(DeleteConfirmation.title(for: workout(exercises: 1, setsEach: 1)) == "delete \"sample leg day\"?")
    }

    @Test func messageCountsWhatGoesWithIt() {
        #expect(DeleteConfirmation.message(for: workout(exercises: 5, setsEach: 3))
                == "its 5 exercises and 15 sets will be deleted too. this can't be undone.")
    }

    @Test func messageUsesSingularWords() {
        #expect(DeleteConfirmation.message(for: workout(exercises: 1, setsEach: 1))
                == "its 1 exercise and 1 set will be deleted too. this can't be undone.")
    }

    @Test func buttonsAreDeleteAndCancel() {
        #expect(DeleteConfirmation.deleteButton == "delete")
        #expect(DeleteConfirmation.cancelButton == "cancel")
    }
}

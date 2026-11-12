// file: WorkoutForm.swift
// what: the editable version of a workout used by the editor screen.
//       numbers are kept as text while typing, then checked and turned into a real workout on save.
// story: us03

import Foundation

// a problem with what the user typed, shown in an alert
struct FormProblem: Error, Equatable {
    let message: String
}

// one set row in the editor
struct SetForm: Identifiable, Equatable {
    let id = UUID()
    var reps = ""
    var weight = ""

    var isBlank: Bool { reps.isEmpty && weight.isEmpty }
}

// one exercise section in the editor
struct ExerciseForm: Identifiable, Equatable {
    let id = UUID()
    var name = ""
    var sets: [SetForm] = [SetForm()]

    // adds a set that copies the last set's reps and weight, so similar sets are one tap
    mutating func addSet() {
        let last = sets.last ?? SetForm()
        sets.append(SetForm(reps: last.reps, weight: last.weight))
    }

    // true if the user never typed anything here
    var isUntouched: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty && sets.allSatisfy(\.isBlank)
    }
}

struct WorkoutForm: Equatable {
    // limits that catch typos (like 1350 instead of 135)
    static let maxReps = 999
    static let maxWeight = 2000.0

    // nil for a new workout, or the id of the workout being edited
    var workoutId: String?
    var name = ""
    var date = Date()
    var exercises: [ExerciseForm] = [ExerciseForm()]

    var isEditing: Bool { workoutId != nil }

    // a blank form for a new workout
    init() {}

    // a form filled in from a saved workout, for editing
    init(workout: Workout) {
        workoutId = workout.id
        name = workout.name
        date = workout.date
        exercises = workout.exercises.map { exercise in
            ExerciseForm(
                name: exercise.name,
                sets: exercise.sets.map { set in
                    SetForm(reps: String(set.reps), weight: WeightText.format(set.weight))
                }
            )
        }
    }

    mutating func addExercise() {
        exercises.append(ExerciseForm())
    }

    // checks everything and builds the workout to save. throws a FormProblem if something is wrong.
    func makeWorkout() throws -> Workout {
        // skip exercise sections the user never touched
        let filledIn = exercises.filter { !$0.isUntouched }
        guard !filledIn.isEmpty else {
            throw FormProblem(message: "add at least one exercise.")
        }

        var result: [Exercise] = []
        for (index, exercise) in filledIn.enumerated() {
            let exerciseName = exercise.name.trimmingCharacters(in: .whitespaces)
            guard !exerciseName.isEmpty else {
                throw FormProblem(message: "exercise \(index + 1) needs a name.")
            }
            guard !exercise.sets.isEmpty else {
                throw FormProblem(message: "\(exerciseName) needs at least one set.")
            }

            var sets: [WorkoutSet] = []
            for (setIndex, set) in exercise.sets.enumerated() {
                let label = "\(exerciseName), set \(setIndex + 1)"
                sets.append(try parse(set, label: label))
            }
            result.append(Exercise(name: exerciseName, sets: sets))
        }

        let workoutName = name.trimmingCharacters(in: .whitespaces)
        return Workout(
            id: workoutId ?? UUID().uuidString,
            name: workoutName.isEmpty ? "workout" : workoutName,
            date: date,
            exercises: result
        )
    }

    // turns the typed text for one set into numbers
    private func parse(_ set: SetForm, label: String) throws -> WorkoutSet {
        guard let reps = Int(set.reps), reps >= 1, reps <= WorkoutForm.maxReps else {
            throw FormProblem(message: "\(label): reps must be a whole number from 1 to \(WorkoutForm.maxReps).")
        }

        // blank weight means bodyweight (0 lbs). accept a comma as the decimal point too.
        let weightText = set.weight.replacingOccurrences(of: ",", with: ".")
        let weight = weightText.isEmpty ? 0 : Double(weightText)
        guard let weight, weight >= 0, weight <= WorkoutForm.maxWeight else {
            throw FormProblem(message: "\(label): weight must be a number from 0 to \(Int(WorkoutForm.maxWeight)) lbs.")
        }
        return WorkoutSet(reps: reps, weight: weight)
    }
}

// file: WorkoutStore.swift
// what: saves, loads, edits, and deletes workouts in the encrypted database.
// story: us03

import Foundation

final class WorkoutStore: ObservableObject {
    // every saved workout, newest first
    @Published private(set) var workouts: [Workout] = []

    private let database: Database

    init(database: Database) {
        self.database = database
        reload()
    }

    // reads all workouts from the database
    func reload() {
        let loaded = (try? loadAll()) ?? []
        workouts = WorkoutSorting.newestFirst(loaded)
    }

    // saves a new workout, or replaces an existing one with the same id
    func save(_ workout: Workout) throws {
        try database.transaction {
            // add the workout, or update its name and date if it already exists
            try database.execute("""
                INSERT INTO workouts (id, name, date) VALUES (?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET name = excluded.name, date = excluded.date;
                """,
                [.text(workout.id), .text(workout.name), .double(workout.date.timeIntervalSince1970)]
            )

            // simplest way to edit: remove the old exercises (their sets go too) and write them again
            try database.execute("DELETE FROM exercises WHERE workout_id = ?;", [.text(workout.id)])

            for (position, exercise) in workout.exercises.enumerated() {
                try database.execute(
                    "INSERT INTO exercises (workout_id, position, name) VALUES (?, ?, ?);",
                    [.text(workout.id), .int(Int64(position)), .text(exercise.name)]
                )
                let exerciseId = database.lastInsertId

                for (setPosition, set) in exercise.sets.enumerated() {
                    try database.execute(
                        "INSERT INTO workout_sets (exercise_id, position, reps, weight_lbs) VALUES (?, ?, ?, ?);",
                        [.int(exerciseId), .int(Int64(setPosition)), .int(Int64(set.reps)), .double(set.weight)]
                    )
                }
            }
        }
        reload()
    }

    // deletes a workout. its exercises and sets are deleted too (on delete cascade).
    func delete(_ workout: Workout) throws {
        try database.execute("DELETE FROM workouts WHERE id = ?;", [.text(workout.id)])
        reload()
    }

    // MARK: private helpers

    private func loadAll() throws -> [Workout] {
        let workoutRows = try database.query("SELECT id, name, date FROM workouts;")

        return try workoutRows.map { row in
            let id = row.text("id") ?? ""
            return Workout(
                id: id,
                name: row.text("name") ?? "",
                date: Date(timeIntervalSince1970: row.double("date") ?? 0),
                exercises: try loadExercises(workoutId: id)
            )
        }
    }

    private func loadExercises(workoutId: String) throws -> [Exercise] {
        let rows = try database.query(
            "SELECT id, name FROM exercises WHERE workout_id = ? ORDER BY position;",
            [.text(workoutId)]
        )
        return try rows.map { row in
            Exercise(
                name: row.text("name") ?? "",
                sets: try loadSets(exerciseId: Int64(row.int("id") ?? 0))
            )
        }
    }

    private func loadSets(exerciseId: Int64) throws -> [WorkoutSet] {
        let rows = try database.query(
            "SELECT reps, weight_lbs FROM workout_sets WHERE exercise_id = ? ORDER BY position;",
            [.int(exerciseId)]
        )
        return rows.map { row in
            WorkoutSet(reps: row.int("reps") ?? 0, weight: row.double("weight_lbs") ?? 0)
        }
    }
}

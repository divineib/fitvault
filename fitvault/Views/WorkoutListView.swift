// file: WorkoutListView.swift
// what: workout history, newest first. tap a workout to edit it, swipe to delete (after a confirm),
//       + to log a new one.
// story: us03, us17

import SwiftUI

struct WorkoutListView: View {
    @EnvironmentObject var store: WorkoutStore

    // the form shown in the editor sheet (nil = sheet closed)
    @State private var editorForm: EditorSheet?

    // the workout waiting for a yes or no before it's deleted (nil = no question showing)
    @State private var pendingDelete: Workout?

    // turns "is a workout waiting?" into the yes/no the alert needs
    private var showingDeleteAlert: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.workouts) { workout in
                    Button {
                        editorForm = EditorSheet(form: WorkoutForm(workout: workout))
                    } label: {
                        WorkoutRow(workout: workout)
                    }
                    .foregroundStyle(.primary)
                    .swipeActions {
                        // us17: ask first instead of deleting right away.
                        // no destructive role here, so the row doesn't vanish before the answer.
                        Button(DeleteConfirmation.deleteButton) {
                            pendingDelete = workout
                        }
                        .tint(.red)
                    }
                }
            }
            .alert(
                pendingDelete.map(DeleteConfirmation.title) ?? "",
                isPresented: showingDeleteAlert,
                presenting: pendingDelete
            ) { workout in
                Button(DeleteConfirmation.deleteButton, role: .destructive) {
                    try? store.delete(workout)
                    pendingDelete = nil
                }
                Button(DeleteConfirmation.cancelButton, role: .cancel) {
                    pendingDelete = nil
                }
            } message: { workout in
                Text(DeleteConfirmation.message(for: workout))
            }
            .overlay {
                if store.workouts.isEmpty {
                    ContentUnavailableView(
                        "no workouts yet",
                        systemImage: "dumbbell",
                        description: Text("tap + to log your first workout.")
                    )
                }
            }
            .navigationTitle("workouts")
            .toolbar {
                Button {
                    editorForm = EditorSheet(form: WorkoutForm())
                } label: {
                    Label("new workout", systemImage: "plus")
                }
            }
            .sheet(item: $editorForm) { sheet in
                WorkoutEditorView(form: sheet.form)
            }
        }
    }
}

// wraps a form so the sheet knows when to open (sheets need something identifiable)
private struct EditorSheet: Identifiable {
    let id = UUID()
    let form: WorkoutForm
}

// one line in the history list
struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(workout.name).font(.headline)
                Spacer()
                Text(workout.date.formatted(date: .abbreviated, time: .omitted).lowercased())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(workout.exercises.map(\.name).joined(separator: ", "))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }

    private var summary: String {
        let exercises = workout.exercises.count
        let sets = workout.setCount
        return "\(exercises) \(exercises == 1 ? "exercise" : "exercises") · \(sets) \(sets == 1 ? "set" : "sets")"
    }
}

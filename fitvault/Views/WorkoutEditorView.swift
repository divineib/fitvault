// file: WorkoutEditorView.swift
// what: the screen for logging a new workout or editing a saved one.
//       "add set" copies the last set so a full workout can be logged quickly.
// story: us03

import SwiftUI

struct WorkoutEditorView: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss

    @State var form: WorkoutForm
    @State private var problem: String?
    @State private var confirmingDelete = false

    // true while the keyboard is up, so we can show a "done" button for the number pad
    @FocusState private var typing: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("name, like push day", text: $form.name)
                        .textInputAutocapitalization(.never)
                        .focused($typing)
                    DatePicker("date", selection: $form.date, displayedComponents: .date)
                }

                ForEach($form.exercises) { $exercise in
                    exerciseSection($exercise)
                }

                Section {
                    Button {
                        form.addExercise()
                    } label: {
                        Label("add exercise", systemImage: "plus.circle.fill")
                    }
                }

                if form.isEditing {
                    Section {
                        Button("delete workout", role: .destructive) {
                            confirmingDelete = true
                        }
                    }
                }
            }
            .navigationTitle(form.isEditing ? "edit workout" : "new workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save", action: save)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("done") { typing = false }
                }
            }
            .alert("can't save yet", isPresented: showingProblem) {
                Button("ok") { problem = nil }
            } message: {
                Text(problem ?? "")
            }
            .confirmationDialog("delete this workout?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("delete", role: .destructive, action: deleteWorkout)
                Button("cancel", role: .cancel) {}
            }
        }
    }

    // MARK: one exercise

    private func exerciseSection(_ exercise: Binding<ExerciseForm>) -> some View {
        Section {
            TextField("exercise, like bench press", text: exercise.name)
                .textInputAutocapitalization(.never)
                .focused($typing)

            ForEach(exercise.sets) { $set in
                HStack {
                    Text("set \(setNumber(set, in: exercise.wrappedValue))")
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .leading)
                    TextField("0", text: $set.reps)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 44)
                        .focused($typing)
                    Text("reps").foregroundStyle(.secondary)
                    Spacer()
                    TextField("0", text: $set.weight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 64)
                        .focused($typing)
                    Text("lbs").foregroundStyle(.secondary)
                }
            }
            .onDelete { offsets in
                exercise.wrappedValue.sets.remove(atOffsets: offsets)
            }

            Button {
                exercise.wrappedValue.addSet()
            } label: {
                Label("add set", systemImage: "plus")
            }
        } header: {
            HStack {
                Text("exercise \(exerciseNumber(exercise.wrappedValue))")
                Spacer()
                // remove the whole exercise
                Button {
                    form.exercises.removeAll { $0.id == exercise.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("remove exercise")
            }
        }
    }

    // MARK: actions

    private func save() {
        do {
            let workout = try form.makeWorkout()
            try store.save(workout)
            dismiss()
        } catch let formProblem as FormProblem {
            problem = formProblem.message
        } catch {
            problem = "something went wrong saving. please try again."
        }
    }

    private func deleteWorkout() {
        guard let id = form.workoutId,
              let saved = store.workouts.first(where: { $0.id == id })
        else { return }
        try? store.delete(saved)
        dismiss()
    }

    // MARK: small helpers

    private var showingProblem: Binding<Bool> {
        Binding(get: { problem != nil }, set: { if !$0 { problem = nil } })
    }

    private func exerciseNumber(_ exercise: ExerciseForm) -> Int {
        (form.exercises.firstIndex { $0.id == exercise.id } ?? 0) + 1
    }

    private func setNumber(_ set: SetForm, in exercise: ExerciseForm) -> Int {
        (exercise.sets.firstIndex { $0.id == set.id } ?? 0) + 1
    }
}

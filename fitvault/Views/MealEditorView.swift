// file: MealEditorView.swift
// what: the screen for adding a meal. calories and protein are required, carbs and fat are optional.
// story: us04

import SwiftUI

struct MealEditorView: View {
    @EnvironmentObject var meals: MealStore
    @Environment(\.dismiss) private var dismiss

    @State private var form = MealForm()
    @State private var problem: String?

    // true while the keyboard is up, so we can show a "done" button for the number pad
    @FocusState private var typing: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("name, like chicken and rice", text: $form.name)
                        .textInputAutocapitalization(.never)
                        .focused($typing)
                }

                Section("required") {
                    numberRow("calories", text: $form.calories, unit: "kcal", keyboard: .numberPad)
                    numberRow("protein", text: $form.protein, unit: "g", keyboard: .decimalPad)
                }

                Section("optional") {
                    numberRow("carbs", text: $form.carbs, unit: "g", keyboard: .decimalPad)
                    numberRow("fat", text: $form.fat, unit: "g", keyboard: .decimalPad)
                }
            }
            .navigationTitle("add meal")
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
        }
    }

    // one number: a label, a box, and its unit
    private func numberRow(_ label: String, text: Binding<String>, unit: String, keyboard: UIKeyboardType) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .focused($typing)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }

    private func save() {
        do {
            try meals.save(try form.makeMeal())
            dismiss()
        } catch let formProblem as FormProblem {
            problem = formProblem.message
        } catch {
            problem = "something went wrong saving. please try again."
        }
    }

    private var showingProblem: Binding<Bool> {
        Binding(get: { problem != nil }, set: { if !$0 { problem = nil } })
    }
}

// file: GoalsView.swift
// what: the screen for setting daily goals for calories, protein, and sleep.
// story: us06

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: GoalsStore

    @State private var form = GoalsForm()
    @State private var problem: String?
    @State private var savedMessage: String?

    // true while the keyboard is up, so we can show a "done" button for the number pad
    @FocusState private var typing: Bool

    var body: some View {
        Form {
            Section {
                goalRow("calories", text: $form.calories, unit: "kcal", keyboard: .numberPad)
                goalRow("protein", text: $form.protein, unit: "g", keyboard: .numberPad)
                goalRow("sleep", text: $form.sleep, unit: "hours", keyboard: .decimalPad)
            } footer: {
                Text("leave a box empty if you don't want a goal for it.")
            }

            Section {
                Button("save goals", action: save)
                if let savedMessage {
                    Text(savedMessage)
                        .font(.footnote)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("daily goals")
        .onAppear {
            form = GoalsForm(goals: store.goals)
        }
        .onChange(of: form) {
            // hide "goals saved." once something is changed again
            savedMessage = nil
        }
        .toolbar {
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

    // one goal: a label, a number box, and its unit
    private func goalRow(_ label: String, text: Binding<String>, unit: String, keyboard: UIKeyboardType) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("none", text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .focused($typing)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)
        }
    }

    private func save() {
        do {
            let goals = try form.makeGoals()
            store.save(goals)
            typing = false
            savedMessage = "goals saved."
        } catch let formProblem as FormProblem {
            problem = formProblem.message
            savedMessage = nil
        } catch {
            problem = "something went wrong saving. please try again."
        }
    }

    private var showingProblem: Binding<Bool> {
        Binding(get: { problem != nil }, set: { if !$0 { problem = nil } })
    }
}

// a short summary for the settings list, like "2,400 kcal · 180 g · 8 h"
enum GoalsSummary {
    static func text(for goals: DailyGoals) -> String {
        var parts: [String] = []
        if let calories = goals.calories { parts.append("\(calories) kcal") }
        if let protein = goals.proteinGrams { parts.append("\(protein) g") }
        if let sleep = goals.sleepHours {
            parts.append("\(sleep.formatted(.number.precision(.fractionLength(0...1)).grouping(.never))) h")
        }
        return parts.isEmpty ? "not set" : parts.joined(separator: " · ")
    }
}

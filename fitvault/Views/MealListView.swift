// file: MealListView.swift
// what: the meals tab. meals grouped by day, newest first, with each day's totals
//       (compared to the daily goals when they're set). + adds a meal, swipe to delete.
// story: us04

import SwiftUI

struct MealListView: View {
    @EnvironmentObject var meals: MealStore
    @EnvironmentObject var goals: GoalsStore

    @State private var addingMeal = false

    // the meal waiting for a yes or no before it's deleted (nil = no question showing)
    @State private var pendingDelete: Meal?

    private var showingDeleteAlert: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(meals.days) { day in
                    Section {
                        ForEach(day.meals) { meal in
                            MealRow(meal: meal)
                                .swipeActions {
                                    Button("delete") { pendingDelete = meal }
                                        .tint(.red)
                                }
                        }
                    } header: {
                        DayTotalsHeader(day: day, goals: goals.goals)
                    }
                }
            }
            .overlay {
                if meals.days.isEmpty {
                    ContentUnavailableView(
                        "no meals yet",
                        systemImage: "fork.knife",
                        description: Text("tap + to log your first meal.")
                    )
                }
            }
            .navigationTitle("meals")
            .toolbar {
                Button {
                    addingMeal = true
                } label: {
                    Label("add meal", systemImage: "plus")
                }
            }
            .sheet(isPresented: $addingMeal) {
                MealEditorView()
            }
            .alert(
                pendingDelete.map { "delete \"\($0.name)\"?" } ?? "",
                isPresented: showingDeleteAlert,
                presenting: pendingDelete
            ) { meal in
                Button("delete", role: .destructive) {
                    try? meals.delete(meal)
                    pendingDelete = nil
                }
                Button("cancel", role: .cancel) { pendingDelete = nil }
            } message: { _ in
                Text("this can't be undone.")
            }
        }
    }
}

// the day's date and totals at the top of each section
struct DayTotalsHeader: View {
    let day: MealDay
    let goals: DailyGoals

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(DayName.text(for: day.day))
                .font(.headline)
                .foregroundStyle(.primary)
            Text(TotalsText.summary(day.totals, goals: goals))
                .font(.subheadline)
        }
        .textCase(nil)
        .padding(.bottom, 4)
    }
}

// one meal in the list
struct MealRow: View {
    let meal: Meal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(meal.name).font(.headline)
                Spacer()
                Text("\(meal.calories) kcal").font(.subheadline)
            }
            Text(MacroText.line(for: meal))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// "today", "yesterday", or a short date like "nov 19"
enum DayName {
    static func text(for day: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(day, inSameDayAs: yesterday) { return "yesterday" }
        return day.formatted(.dateTime.month(.abbreviated).day()).lowercased()
    }
}

// the totals line, like "1,250 / 2,200 kcal · 95 / 180 g protein"
enum TotalsText {
    static func summary(_ totals: DailyTotals, goals: DailyGoals) -> String {
        let calories = goals.calories.map { "\(totals.calories) / \($0) kcal" } ?? "\(totals.calories) kcal"
        let protein = GramsText.format(totals.proteinGrams)
        let proteinPart = goals.proteinGrams.map { "\(protein) / \($0) g protein" } ?? "\(protein) g protein"
        return "\(calories) · \(proteinPart)"
    }
}

// the macro line under a meal, like "32 g protein · 40 g carbs · 12 g fat"
enum MacroText {
    static func line(for meal: Meal) -> String {
        var parts = ["\(GramsText.format(meal.proteinGrams)) g protein"]
        if let carbs = meal.carbsGrams { parts.append("\(GramsText.format(carbs)) g carbs") }
        if let fat = meal.fatGrams { parts.append("\(GramsText.format(fat)) g fat") }
        return parts.joined(separator: " · ")
    }
}

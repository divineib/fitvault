// file: ContentView.swift
// what: the main screen once unlocked: workouts, meals, and settings tabs.
// story: us01, us02, us03, us04

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WorkoutListView()
                .tabItem { Label("workouts", systemImage: "dumbbell") }

            MealListView()
                .tabItem { Label("meals", systemImage: "fork.knife") }

            SettingsView()
                .tabItem { Label("settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    let model = AppModel()
    return ContentView()
        .environmentObject(model)
        .environmentObject(model.lock!)
        .environmentObject(model.workouts!)
        .environmentObject(model.goals!)
        .environmentObject(model.meals!)
}

// file: ContentView.swift
// what: the main screen once unlocked: a workouts tab and a settings tab.
// story: us01, us02, us03

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WorkoutListView()
                .tabItem { Label("workouts", systemImage: "dumbbell") }

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
}

// file: FitvaultApp.swift
// what: the app's starting point. opens the encrypted database, shows the lock,
//       tells the lock when the app goes to the background, and hides the app
//       behind a cover whenever it isn't active.
// story: us01, us02, us03, us04, us06, us15

import SwiftUI

@main
struct FitvaultApp: App {
    // one shared model for the whole app
    @StateObject private var model = AppModel()

    // tells us when the app moves to the background or comes back
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let lock = model.lock, let workouts = model.workouts, let goals = model.goals, let meals = model.meals {
                    RootView()
                        .environmentObject(model)
                        .environmentObject(lock)
                        .environmentObject(workouts)
                        .environmentObject(goals)
                        .environmentObject(meals)
                } else {
                    // the database could not be opened, so we stop here
                    StartupErrorView(message: model.startupError ?? "unknown error")
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: model.lock?.appWentToBackground()
            case .active: model.lock?.appBecameActive()
            default: break
            }
            // us15: cover everything, including sheets and alerts, unless the app is active
            if PrivacyRule.shouldCover(phase) { PrivacyWindow.show() } else { PrivacyWindow.hide() }
        }
    }
}

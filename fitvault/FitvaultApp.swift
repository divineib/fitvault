// file: FitvaultApp.swift
// what: the app's starting point. opens the encrypted database, shows the lock,
//       tells the lock when the app goes to the background, and hides the app
//       behind a cover whenever it isn't active.
// story: us01, us02, us03, us15

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
                if let lock = model.lock, let workouts = model.workouts {
                    RootView()
                        .environmentObject(model)
                        .environmentObject(lock)
                        .environmentObject(workouts)
                } else {
                    // the database could not be opened, so we stop here
                    StartupErrorView(message: model.startupError ?? "unknown error")
                }

                // us15: hide everything when the app isn't active,
                // so the app switcher preview shows this cover instead of data
                if PrivacyRule.shouldCover(scenePhase) {
                    PrivacyCoverView()
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: model.lock?.appWentToBackground()
            case .active: model.lock?.appBecameActive()
            default: break
            }
        }
    }
}

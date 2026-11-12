// file: FitvaultApp.swift
// what: the app's starting point. opens the encrypted database, shows the lock,
//       and tells the lock when the app goes to the background.
// story: us01, us02

import SwiftUI

@main
struct FitvaultApp: App {
    // one shared model for the whole app
    @StateObject private var model = AppModel()

    // tells us when the app moves to the background or comes back
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if let lock = model.lock {
                RootView()
                    .environmentObject(model)
                    .environmentObject(lock)
            } else {
                // the database could not be opened, so we stop here
                StartupErrorView(message: model.startupError ?? "unknown error")
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

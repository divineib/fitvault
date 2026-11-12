// file: FitvaultApp.swift
// what: the app's starting point. opens the encrypted database and shows the first screen.
// story: us01

import SwiftUI

@main
struct FitvaultApp: App {
    // one shared model for the whole app
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            if let error = model.startupError {
                // the database could not be opened, so we stop here
                StartupErrorView(message: error)
            } else {
                ContentView()
                    .environmentObject(model)
            }
        }
    }
}

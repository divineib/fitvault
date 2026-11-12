// file: RootView.swift
// what: picks which screen to show: create a pin, the lock screen, or the app.
// story: us02

import SwiftUI

struct RootView: View {
    @EnvironmentObject var lock: LockManager

    var body: some View {
        if !lock.hasPin {
            CreatePinView()
        } else if !lock.isUnlocked {
            LockView()
        } else {
            ContentView()
        }
    }
}

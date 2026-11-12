// file: ContentView.swift
// what: the main screen of the app.
// story: us01, us02

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var lock: LockManager

    var body: some View {
        NavigationStack {
            List {
                Section("settings") {
                    NavigationLink("security") {
                        SecurityView()
                    }

                    // face id on or off
                    Toggle("unlock with \(Biometrics.name())", isOn: Binding(
                        get: { lock.biometricsEnabled },
                        set: { lock.setBiometrics(enabled: $0) }
                    ))
                    .disabled(!Biometrics.isAvailable() && !lock.biometricsEnabled)

                    Button("lock now") {
                        lock.lock()
                    }
                }
            }
            .navigationTitle("fitvault")
        }
    }
}

#Preview {
    let model = AppModel()
    return ContentView()
        .environmentObject(model)
        .environmentObject(model.lock!)
}

// file: SettingsView.swift
// what: the settings tab (daily goals, security screen, face id switch, lock now).
// story: us01, us02, us06

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lock: LockManager
    @EnvironmentObject var goals: GoalsStore

    var body: some View {
        NavigationStack {
            List {
                Section("goals") {
                    NavigationLink {
                        GoalsView()
                    } label: {
                        LabeledContent("daily goals", value: GoalsSummary.text(for: goals.goals))
                    }
                }

                Section("privacy") {
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
            .navigationTitle("settings")
        }
    }
}

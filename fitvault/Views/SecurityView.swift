// file: SecurityView.swift
// what: shows the security checks passing, plus proof that data survives restarts.
// story: us01

import SwiftUI

struct SecurityView: View {
    @EnvironmentObject var model: AppModel
    @State private var checks: [SecurityCheck] = []

    var body: some View {
        List {
            Section("checks") {
                ForEach(checks) { check in
                    Label {
                        Text(check.title)
                    } icon: {
                        Image(systemName: check.passed ? "checkmark.shield.fill" : "xmark.shield.fill")
                            .foregroundStyle(check.passed ? .green : .red)
                    }
                }
            }

            Section("details") {
                LabeledContent("encryption", value: "sqlcipher \(model.database?.cipherVersion() ?? "?")")
                LabeledContent("key size", value: "256-bit, random")
                LabeledContent("vault opened", value: "\(model.launchCount) times")
            }

            Section {
                Text("your data is saved in an encrypted database on this phone. the key is made on first launch and kept in the keychain. there are no accounts and no servers.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("security")
        .onAppear {
            if let database = model.database {
                checks = SecurityChecks.run(database: database)
            }
        }
    }
}

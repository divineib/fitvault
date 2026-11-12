// file: StartupErrorView.swift
// what: shown instead of the app if the encrypted database could not be opened.
// story: us01

import SwiftUI

struct StartupErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("fitvault can't open your data")
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

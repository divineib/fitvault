// file: PrivacyCoverView.swift
// what: a plain cover shown whenever the app isn't active, so the app switcher
//       preview never shows workout or health data.
// story: us15

import SwiftUI

enum PrivacyRule {
    // cover the screen unless the app is fully active.
    // "inactive" covers the app switcher, the face id prompt, and system sheets.
    static func shouldCover(_ phase: ScenePhase) -> Bool {
        phase != .active
    }
}

struct PrivacyCoverView: View {
    var body: some View {
        ZStack {
            // solid background so nothing behind it shows through
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.tint)
                Text("fitvault")
                    .font(.title2.bold())
            }
        }
        .accessibilityLabel("fitvault is hidden")
    }
}

#Preview {
    PrivacyCoverView()
}

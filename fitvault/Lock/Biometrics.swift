// file: Biometrics.swift
// what: asks ios for face id or touch id.
// story: us02

import Foundation
import LocalAuthentication

enum Biometrics {
    // true if this phone has face id or touch id set up
    static func isAvailable() -> Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    // "face id" or "touch id", for labels
    static func name() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType == .touchID ? "touch id" : "face id"
    }

    // shows the system face id / touch id prompt. true if it matched.
    static func authenticate() async -> Bool {
        let context = LAContext()
        // hides the "enter password" fallback, since we have our own pin screen
        context.localizedFallbackTitle = ""
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "unlock fitvault"
            )
        } catch {
            return false
        }
    }
}

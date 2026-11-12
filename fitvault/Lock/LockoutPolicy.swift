// file: LockoutPolicy.swift
// what: the rules for wrong pins (5 wrong = blocked for 30 seconds)
//       and for auto-lock (locks after 2 minutes in the background).
// story: us02

import Foundation

struct LockoutState: Equatable {
    static let maxAttempts = 5
    static let lockoutSeconds: TimeInterval = 30

    // wrong pins in a row since the last success or lockout
    var failedAttempts = 0

    // when the block ends, or nil if not blocked
    var lockedUntil: Date?

    // true while pin entry is blocked
    func isLockedOut(now: Date) -> Bool {
        guard let lockedUntil else { return false }
        return now < lockedUntil
    }

    // whole seconds left in the block (rounded up), or 0
    func secondsLeft(now: Date) -> Int {
        guard let lockedUntil, now < lockedUntil else { return 0 }
        return Int(lockedUntil.timeIntervalSince(now).rounded(.up))
    }

    // tries left before the next block
    var attemptsLeft: Int {
        LockoutState.maxAttempts - failedAttempts
    }

    // call after a wrong pin. the 5th one starts the block.
    mutating func recordFailure(now: Date) {
        failedAttempts += 1
        if failedAttempts >= LockoutState.maxAttempts {
            lockedUntil = now.addingTimeInterval(LockoutState.lockoutSeconds)
            failedAttempts = 0
        }
    }

    // call after a right pin
    mutating func recordSuccess() {
        failedAttempts = 0
        lockedUntil = nil
    }
}

enum AutoLockRule {
    // 2 minutes
    static let backgroundTimeout: TimeInterval = 120

    // true if the app was in the background long enough to need the pin again
    static func shouldLock(backgroundedAt: Date?, now: Date) -> Bool {
        guard let backgroundedAt else { return false }
        return now.timeIntervalSince(backgroundedAt) >= backgroundTimeout
    }
}

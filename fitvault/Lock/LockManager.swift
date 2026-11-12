// file: LockManager.swift
// what: decides if the app is locked. creates the pin, checks pins, counts wrong tries,
//       and locks again after 2 minutes in the background. saves its state in the encrypted database.
// story: us02

import Foundation

final class LockManager: ObservableObject {
    // true once a pin has been made
    @Published private(set) var hasPin: Bool

    // true after the right pin or face id. starts false on every launch.
    @Published private(set) var isUnlocked = false

    // true if the user turned on face id / touch id
    @Published private(set) var biometricsEnabled: Bool

    // wrong-pin counter and block time
    @Published private(set) var lockout: LockoutState

    private let settings: SettingsStore
    private let iterations: Int
    private var backgroundedAt: Date?

    // names used in the settings table
    private enum Keys {
        static let pinHash = "pin_hash"
        static let pinSalt = "pin_salt"
        static let pinIterations = "pin_iterations"
        static let failedAttempts = "failed_attempts"
        static let lockedUntil = "locked_until"
        static let biometrics = "biometrics_enabled"
    }

    init(settings: SettingsStore, iterations: Int = PinHasher.defaultIterations) {
        self.settings = settings
        self.iterations = iterations
        hasPin = settings.string(Keys.pinHash) != nil
        biometricsEnabled = settings.string(Keys.biometrics) == "1"

        // load the wrong-pin state, so a block survives closing the app
        var saved = LockoutState()
        saved.failedAttempts = settings.int(Keys.failedAttempts) ?? 0
        if let seconds = settings.string(Keys.lockedUntil).flatMap(Double.init) {
            saved.lockedUntil = Date(timeIntervalSince1970: seconds)
        }
        lockout = saved
    }

    // MARK: creating the pin

    // saves a new pin as a salted hash and unlocks the app
    func createPin(_ pin: String, useBiometrics: Bool) throws {
        guard PinRules.isValid(pin) else { return }
        let made = try PinHasher.makeHash(pin: pin, iterations: iterations)
        settings.set(Keys.pinHash, to: made.hash.hexString)
        settings.set(Keys.pinSalt, to: made.salt.hexString)
        settings.set(Keys.pinIterations, to: String(made.iterations))
        setBiometrics(enabled: useBiometrics)
        hasPin = true
        isUnlocked = true
    }

    // MARK: unlocking

    // checks a typed pin. returns true if it was right.
    @discardableResult
    func tryPin(_ pin: String, now: Date = Date()) -> Bool {
        // no guesses allowed during a block
        guard !lockout.isLockedOut(now: now), let saved = savedPinHash() else { return false }

        if PinHasher.verify(pin: pin, against: saved) {
            lockout.recordSuccess()
            saveLockout()
            isUnlocked = true
            return true
        } else {
            lockout.recordFailure(now: now)
            saveLockout()
            return false
        }
    }

    // shows the face id prompt and unlocks if it matches
    @MainActor
    func tryBiometrics() async {
        guard biometricsEnabled, Biometrics.isAvailable() else { return }
        if await Biometrics.authenticate() {
            lockout.recordSuccess()
            saveLockout()
            isUnlocked = true
        }
    }

    // locks right away (used by the "lock now" button)
    func lock() {
        isUnlocked = false
    }

    // MARK: background timer

    func appWentToBackground(now: Date = Date()) {
        backgroundedAt = now
    }

    func appBecameActive(now: Date = Date()) {
        if AutoLockRule.shouldLock(backgroundedAt: backgroundedAt, now: now) {
            isUnlocked = false
        }
        backgroundedAt = nil
    }

    // MARK: settings

    func setBiometrics(enabled: Bool) {
        biometricsEnabled = enabled
        settings.set(Keys.biometrics, to: enabled ? "1" : "0")
    }

    // true if the pin is saved as a hash with a salt (shown on the security screen)
    var pinIsStoredAsHash: Bool {
        guard let saved = savedPinHash() else { return false }
        return saved.hash.count == PinHasher.hashLength && saved.salt.count == PinHasher.saltLength
    }

    // MARK: private helpers

    private func savedPinHash() -> PinHash? {
        guard let hash = settings.string(Keys.pinHash).flatMap(Data.init(hexString:)),
              let salt = settings.string(Keys.pinSalt).flatMap(Data.init(hexString:)),
              let rounds = settings.int(Keys.pinIterations)
        else { return nil }
        return PinHash(hash: hash, salt: salt, iterations: rounds)
    }

    private func saveLockout() {
        settings.set(Keys.failedAttempts, to: String(lockout.failedAttempts))
        if let lockedUntil = lockout.lockedUntil {
            settings.set(Keys.lockedUntil, to: String(lockedUntil.timeIntervalSince1970))
        } else {
            settings.remove(Keys.lockedUntil)
        }
    }
}

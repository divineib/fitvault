// file: LockTests.swift
// what: tests the lockout rules, the 2-minute auto-lock, and that the lock state survives a restart.
// story: us02

import Foundation
import Testing
@testable import fitvault

struct LockTests {
    let start = Date(timeIntervalSince1970: 1_000_000)

    // a lock manager on a fresh test database, with fast hashing
    func makeLock(settings: SettingsStore? = nil) throws -> LockManager {
        let store = try settings ?? SettingsStore(database: TestHelpers.makeDatabase())
        return LockManager(settings: store, iterations: 1_000)
    }

    // MARK: lockout rules

    @Test func fourWrongPinsDoNotBlock() {
        var state = LockoutState()
        for _ in 1...4 { state.recordFailure(now: start) }
        #expect(!state.isLockedOut(now: start))
        #expect(state.attemptsLeft == 1)
    }

    @Test func fiveWrongPinsBlockFor30Seconds() {
        var state = LockoutState()
        for _ in 1...5 { state.recordFailure(now: start) }
        #expect(state.isLockedOut(now: start))
        #expect(state.secondsLeft(now: start) == 30)
        #expect(state.isLockedOut(now: start.addingTimeInterval(29)))
        #expect(!state.isLockedOut(now: start.addingTimeInterval(30)))
    }

    @Test func rightPinResetsTheCount() {
        var state = LockoutState()
        for _ in 1...3 { state.recordFailure(now: start) }
        state.recordSuccess()
        #expect(state.failedAttempts == 0)
        #expect(state.attemptsLeft == 5)
    }

    // MARK: auto-lock after 2 minutes

    @Test func autoLockAfterTwoMinutes() {
        #expect(!AutoLockRule.shouldLock(backgroundedAt: nil, now: start))
        #expect(!AutoLockRule.shouldLock(backgroundedAt: start, now: start.addingTimeInterval(119)))
        #expect(AutoLockRule.shouldLock(backgroundedAt: start, now: start.addingTimeInterval(120)))
    }

    @Test func managerLocksAfterLongBackground() throws {
        let lock = try makeLock()
        try lock.createPin("1234", useBiometrics: false)
        #expect(lock.isUnlocked)

        // a short trip to the background keeps it unlocked
        lock.appWentToBackground(now: start)
        lock.appBecameActive(now: start.addingTimeInterval(60))
        #expect(lock.isUnlocked)

        // 2 minutes or more locks it
        lock.appWentToBackground(now: start)
        lock.appBecameActive(now: start.addingTimeInterval(120))
        #expect(!lock.isUnlocked)
    }

    // MARK: lock manager

    @Test func newPinIsSavedAsHashNotPlainText() throws {
        let settings = SettingsStore(database: try TestHelpers.makeDatabase())
        let lock = try makeLock(settings: settings)
        try lock.createPin("975310", useBiometrics: false)

        #expect(lock.hasPin)
        #expect(lock.pinIsStoredAsHash)

        // the pin must not appear in any saved setting
        let rows = try settings.database.query("SELECT value FROM settings;")
        #expect(rows.allSatisfy { $0.text("value") != "975310" })
        #expect(rows.allSatisfy { !($0.text("value") ?? "").contains("975310") })
    }

    @Test func invalidPinIsNotSaved() throws {
        let lock = try makeLock()
        try lock.createPin("12", useBiometrics: false)
        #expect(!lock.hasPin)
    }

    @Test func appStartsLockedEveryLaunch() throws {
        let settings = SettingsStore(database: try TestHelpers.makeDatabase())
        try makeLock(settings: settings).createPin("1234", useBiometrics: false)

        // a new lock manager = the app opening again
        let relaunched = try makeLock(settings: settings)
        #expect(relaunched.hasPin)
        #expect(!relaunched.isUnlocked)
        #expect(relaunched.tryPin("1234"))
        #expect(relaunched.isUnlocked)
    }

    @Test func blockSurvivesClosingTheApp() throws {
        let settings = SettingsStore(database: try TestHelpers.makeDatabase())
        let lock = try makeLock(settings: settings)
        try lock.createPin("1234", useBiometrics: false)
        lock.lock()

        for _ in 1...5 { lock.tryPin("0000", now: start) }
        #expect(lock.lockout.isLockedOut(now: start))

        // reopen the app 10 seconds later: still blocked, even with the right pin
        let relaunched = try makeLock(settings: settings)
        #expect(relaunched.lockout.isLockedOut(now: start.addingTimeInterval(10)))
        #expect(!relaunched.tryPin("1234", now: start.addingTimeInterval(10)))

        // after 30 seconds the right pin works again
        #expect(relaunched.tryPin("1234", now: start.addingTimeInterval(31)))
    }

    @Test func wrongCountSurvivesClosingTheApp() throws {
        let settings = SettingsStore(database: try TestHelpers.makeDatabase())
        let lock = try makeLock(settings: settings)
        try lock.createPin("1234", useBiometrics: false)
        for _ in 1...3 { lock.tryPin("0000", now: start) }

        // closing and reopening must not reset the count to 0
        let relaunched = try makeLock(settings: settings)
        #expect(relaunched.lockout.failedAttempts == 3)
    }

    @Test func biometricsSettingIsSaved() throws {
        let settings = SettingsStore(database: try TestHelpers.makeDatabase())
        let lock = try makeLock(settings: settings)
        lock.setBiometrics(enabled: true)
        #expect(try makeLock(settings: settings).biometricsEnabled)
        lock.setBiometrics(enabled: false)
        #expect(try !makeLock(settings: settings).biometricsEnabled)
    }
}

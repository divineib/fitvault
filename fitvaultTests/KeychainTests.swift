// file: KeychainTests.swift
// what: tests that the database key is random, saved in the keychain, and reused.
// story: us01

import Foundation
import Testing
@testable import fitvault

struct KeychainTests {

    @Test func saveReadAndDelete() {
        let account = "test-\(UUID().uuidString)"
        let data = Data("abc".utf8)

        #expect(KeychainHelper.save(data, account: account))
        #expect(KeychainHelper.read(account: account) == data)

        KeychainHelper.delete(account: account)
        #expect(KeychainHelper.read(account: account) == nil)
    }

    @Test func keyIsDeviceOnly() {
        let account = "test-\(UUID().uuidString)"
        defer { KeychainHelper.delete(account: account) }

        KeychainHelper.save(Data("abc".utf8), account: account)
        #expect(KeychainHelper.isDeviceOnly(account: account))
    }

    @Test func databaseKeyIsMadeOnceAndReused() throws {
        let account = "test-\(UUID().uuidString)"
        defer { KeychainHelper.delete(account: account) }

        let first = try DatabaseKey.loadOrCreate(account: account)
        let second = try DatabaseKey.loadOrCreate(account: account)

        #expect(first.count == 32)
        #expect(first == second)
    }

    @Test func randomKeysAreDifferent() throws {
        let a = try DatabaseKey.randomBytes(count: 32)
        let b = try DatabaseKey.randomBytes(count: 32)
        #expect(a != b)
    }
}

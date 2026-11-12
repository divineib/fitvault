// file: PinTests.swift
// what: tests pin rules and pbkdf2 pin hashing.
// story: us02

import Foundation
import Testing
@testable import fitvault

struct PinTests {
    // fewer rounds so the tests run fast. the app uses the full 600,000.
    let fastRounds = 1_000

    @Test func pinMustBe4To6Digits() {
        #expect(PinRules.isValid("1234"))
        #expect(PinRules.isValid("12345"))
        #expect(PinRules.isValid("123456"))

        #expect(!PinRules.isValid("123"))       // too short
        #expect(!PinRules.isValid("1234567"))   // too long
        #expect(!PinRules.isValid("12a4"))      // letters
        #expect(!PinRules.isValid("12 34"))     // spaces
        #expect(!PinRules.isValid("١٢٣٤"))      // non-ascii digits
    }

    @Test func rightPinVerifiesWrongPinDoesNot() throws {
        let saved = try PinHasher.makeHash(pin: "2468", iterations: fastRounds)
        #expect(PinHasher.verify(pin: "2468", against: saved))
        #expect(!PinHasher.verify(pin: "2469", against: saved))
        #expect(!PinHasher.verify(pin: "", against: saved))
    }

    @Test func samePinGetsDifferentHashBecauseOfSalt() throws {
        let a = try PinHasher.makeHash(pin: "1111", iterations: fastRounds)
        let b = try PinHasher.makeHash(pin: "1111", iterations: fastRounds)
        #expect(a.salt != b.salt)
        #expect(a.hash != b.hash)
    }

    @Test func hashIsTheRightSizeAndNotThePin() throws {
        let saved = try PinHasher.makeHash(pin: "1234", iterations: fastRounds)
        #expect(saved.hash.count == 32)
        #expect(saved.salt.count == 16)
        #expect(saved.hash.range(of: Data("1234".utf8)) == nil)
    }

    @Test func knownPbkdf2Answer() {
        // a published pbkdf2-hmac-sha256 test vector, so we know commoncrypto is called correctly
        let result = PinHasher.derive(pin: "password", salt: Data("salt".utf8), iterations: 1)
        #expect(result.hexString == "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b")
    }

    @Test func hexRoundTrip() {
        let bytes = Data([0x00, 0x0a, 0xff, 0x10])
        #expect(bytes.hexString == "000aff10")
        #expect(Data(hexString: "000aff10") == bytes)
        #expect(Data(hexString: "abc") == nil)
        #expect(Data(hexString: "zz") == nil)
    }
}

// file: PinHasher.swift
// what: turns a pin into a salted pbkdf2 hash, and checks a pin against a saved hash.
//       the pin itself is never saved.
// story: us02

import Foundation
import CommonCrypto

struct PinHash: Equatable {
    let hash: Data
    let salt: Data
    let iterations: Int
}

enum PinHasher {
    // how many times pbkdf2 repeats the work. more = slower to guess.
    // 600,000 is the owasp recommendation for pbkdf2 with sha-256.
    static let defaultIterations = 600_000

    // 16 random bytes of salt, so two people with the same pin get different hashes
    static let saltLength = 16

    // 32 bytes of output (sha-256 size)
    static let hashLength = 32

    // makes a new salt and hashes the pin with it
    static func makeHash(pin: String, iterations: Int = defaultIterations) throws -> PinHash {
        let salt = try DatabaseKey.randomBytes(count: saltLength)
        let hash = derive(pin: pin, salt: salt, iterations: iterations)
        return PinHash(hash: hash, salt: salt, iterations: iterations)
    }

    // hashes the typed pin with the saved salt and compares the result
    static func verify(pin: String, against saved: PinHash) -> Bool {
        let attempt = derive(pin: pin, salt: saved.salt, iterations: saved.iterations)
        return constantTimeEquals(attempt, saved.hash)
    }

    // runs pbkdf2 with hmac-sha256 using apple's commoncrypto
    static func derive(pin: String, salt: Data, iterations: Int) -> Data {
        let password = Array(pin.utf8)
        let saltBytes = [UInt8](salt)
        var output = [UInt8](repeating: 0, count: hashLength)

        CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            password.map { Int8(bitPattern: $0) }, password.count,
            saltBytes, saltBytes.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            UInt32(iterations),
            &output, output.count
        )
        return Data(output)
    }

    // compares every byte so the time taken doesn't hint at how close a guess was
    static func constantTimeEquals(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        var difference: UInt8 = 0
        for (x, y) in zip(a, b) {
            difference |= x ^ y
        }
        return difference == 0
    }
}

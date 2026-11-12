// file: PinRules.swift
// what: the rules for a valid pin (4 to 6 digits).
// story: us02

import Foundation

enum PinRules {
    static let minLength = 4
    static let maxLength = 6

    // true if the pin is only digits and 4 to 6 long
    static func isValid(_ pin: String) -> Bool {
        guard pin.count >= minLength, pin.count <= maxLength else { return false }
        return pin.allSatisfy { $0.isASCII && $0.isNumber }
    }
}

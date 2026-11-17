// file: PrivacyTests.swift
// what: tests when the privacy cover should show.
// story: us15

import SwiftUI
import Testing
@testable import fitvault

struct PrivacyTests {

    @Test func coverShowsUnlessActive() {
        #expect(PrivacyRule.shouldCover(.inactive))     // app switcher, face id prompt, sheets
        #expect(PrivacyRule.shouldCover(.background))   // app in the background
        #expect(!PrivacyRule.shouldCover(.active))      // normal use
    }
}

//
//  AnalyticsUserPropertyTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
import XCTest

final class AnalyticsUserPropertyTests: XCTestCase {
    func test_names_fitFirebaseLimits() {
        let allowedCharacters = Set("abcdefghijklmnopqrstuvwxyz0123456789_")
        for property in AnalyticsUserProperty.allCases {
            let name = property.rawValue
            XCTAssertLessThanOrEqual(name.count, AnalyticsUserProperty.maxNameLength, name)
            XCTAssertTrue(name.allSatisfy(allowedCharacters.contains), name)
            XCTAssertTrue(name.first?.isLetter ?? false, name)
            XCTAssertFalse(["firebase_", "google_", "ga_"].contains { name.hasPrefix($0) }, name)
        }
    }
}

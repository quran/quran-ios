//
//  AnalyticsUserPropertyValueTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
import XCTest

final class AnalyticsUserPropertyValueTests: XCTestCase {
    func test_decimal() {
        XCTAssertEqual(AnalyticsUserPropertyValue.decimal(0), "0.0")
        XCTAssertEqual(AnalyticsUserPropertyValue.decimal(1.25), "1.25")
        XCTAssertEqual(AnalyticsUserPropertyValue.decimal(1.5), "1.5")
        XCTAssertEqual(AnalyticsUserPropertyValue.decimal(2), "2.0")
        XCTAssertEqual(AnalyticsUserPropertyValue.decimal(Double(Float(1.1))), "1.1")
    }

    func test_countBucket() {
        XCTAssertEqual(AnalyticsUserPropertyValue.countBucket(0), "0")
        XCTAssertEqual(AnalyticsUserPropertyValue.countBucket(1), "1")
        XCTAssertEqual(AnalyticsUserPropertyValue.countBucket(2), "2")
        XCTAssertEqual(AnalyticsUserPropertyValue.countBucket(3), "3+")
        XCTAssertEqual(AnalyticsUserPropertyValue.countBucket(42), "3+")
    }

    func test_limited() {
        XCTAssertEqual(AnalyticsUserPropertyValue.limited(String(repeating: "a", count: 50)).count, 36)
        XCTAssertEqual(AnalyticsUserPropertyValue.limited("en"), "en")
    }
}

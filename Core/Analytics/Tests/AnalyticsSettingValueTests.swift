//
//  AnalyticsSettingValueTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
import XCTest

final class AnalyticsSettingValueTests: XCTestCase {
    func test_decimal() {
        XCTAssertEqual(AnalyticsSettingValue.decimal(0), "0.0")
        XCTAssertEqual(AnalyticsSettingValue.decimal(1.25), "1.25")
        XCTAssertEqual(AnalyticsSettingValue.decimal(1.5), "1.5")
        XCTAssertEqual(AnalyticsSettingValue.decimal(2), "2.0")
        XCTAssertEqual(AnalyticsSettingValue.decimal(Double(Float(1.1))), "1.1")
    }

    func test_countBucket() {
        XCTAssertEqual(AnalyticsSettingValue.countBucket(0), "0")
        XCTAssertEqual(AnalyticsSettingValue.countBucket(1), "1")
        XCTAssertEqual(AnalyticsSettingValue.countBucket(2), "2")
        XCTAssertEqual(AnalyticsSettingValue.countBucket(3), "3+")
        XCTAssertEqual(AnalyticsSettingValue.countBucket(42), "3+")
    }

    func test_limited() {
        XCTAssertEqual(AnalyticsSettingValue.limited(String(repeating: "a", count: 150)).count, 100)
        XCTAssertEqual(AnalyticsSettingValue.limited("en"), "en")
    }
}

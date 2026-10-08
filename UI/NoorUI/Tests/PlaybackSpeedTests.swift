//
//  PlaybackSpeedTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-08.
//

import XCTest
@testable import NoorUI

final class PlaybackSpeedTests: XCTestCase {
    func testSupportedRatesIncludeDefaultAndFineStepsAroundIt() {
        let rates = PlaybackSpeed.supportedRates
        // 1.0 is the stored default; without it no picker would show a checkmark.
        XCTAssertTrue(rates.contains(1.0))
        XCTAssertTrue(rates.contains(0.9))
        XCTAssertTrue(rates.contains(1.1))
    }

    func testSupportedRatesAreStrictlyAscending() {
        let rates = PlaybackSpeed.supportedRates
        XCTAssertTrue(zip(rates, rates.dropFirst()).allSatisfy { $0 < $1 })
    }

    func testEverySupportedRateHasADistinctLabel() {
        let rates = PlaybackSpeed.supportedRates
        XCTAssertEqual(Set(rates.map(PlaybackSpeed.formatted)).count, rates.count)
    }
}

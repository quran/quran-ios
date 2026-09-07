//
//  RunsPreferenceTests.swift
//
//
//  Created by Abdullah Levin on 2026-09-08.
//

import QueuePlayer
import XCTest
@testable import QuranAudioKit

final class RunsPreferenceTests: XCTestCase {
    func testFiniteRunsSurviveARoundTrip() {
        for count in [1, 3, 25, 100] {
            let stored = Runs.finite(count).preferenceValue
            XCTAssertEqual(Runs(preferenceValue: stored), .finite(count))
        }
    }

    func testEndlessRepetitionIsStoredAsZero() {
        XCTAssertEqual(Runs.indefinite.preferenceValue, 0)
        XCTAssertEqual(Runs(preferenceValue: 0), .indefinite)
    }

    func testASingleRunIsNotStoredTheSameWayAsEndlessRepetition() {
        XCTAssertNotEqual(Runs.finite(1).preferenceValue, Runs.indefinite.preferenceValue)
    }

    func testStoredCountsBelowOneReadBackAsEndlessRepetition() {
        XCTAssertEqual(Runs(preferenceValue: -1), .indefinite)
    }

    func testACountBelowOneIsNeverStored() {
        XCTAssertEqual(Runs.finite(0).preferenceValue, 1)
        XCTAssertEqual(Runs.finite(-3).preferenceValue, 1)
    }
}

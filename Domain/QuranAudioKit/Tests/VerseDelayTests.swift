//
//  VerseDelayTests.swift
//
//
//  Created by Abdirizak Hassan on 6/5/26.
//  Copyright © 2026 Abdirizak Hassan. All rights reserved.
//

import XCTest
@testable import QueuePlayer

final class VerseDelayTests: XCTestCase {
    func test_multiplier_mapsEachCaseToItsFraction() {
        XCTAssertEqual(VerseDelay.none.multiplier, 0)
        XCTAssertEqual(VerseDelay.quarter.multiplier, 0.25)
        XCTAssertEqual(VerseDelay.half.multiplier, 0.5)
        XCTAssertEqual(VerseDelay.threeQuarters.multiplier, 0.75)
        XCTAssertEqual(VerseDelay.full.multiplier, 1)
        XCTAssertEqual(VerseDelay.oneAndQuarter.multiplier, 1.25)
        XCTAssertEqual(VerseDelay.oneAndHalf.multiplier, 1.5)
        XCTAssertEqual(VerseDelay.oneAndThreeQuarters.multiplier, 1.75)
        XCTAssertEqual(VerseDelay.double.multiplier, 2)
        XCTAssertEqual(VerseDelay.twoAndQuarter.multiplier, 2.25)
        XCTAssertEqual(VerseDelay.twoAndHalf.multiplier, 2.5)
        XCTAssertEqual(VerseDelay.twoAndThreeQuarters.multiplier, 2.75)
        XCTAssertEqual(VerseDelay.triple.multiplier, 3)
    }

    func test_none_isTheDefaultAndHasNoDelay() {
        XCTAssertEqual(VerseDelay.none.multiplier, 0)
        // none is the first/raw-zero case so it backs the stored preference default.
        XCTAssertEqual(VerseDelay.none.rawValue, 0)
    }

    func test_allCases_areOrderedByIncreasingMultiplier() {
        let multipliers = VerseDelay.allCases.map(\.multiplier)
        XCTAssertEqual(multipliers, multipliers.sorted())
    }
}

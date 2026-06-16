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
        XCTAssertEqual(VerseDelay.double.multiplier, 2)
    }

    func test_none_isTheDefaultAndHasNoDelay() {
        XCTAssertEqual(VerseDelay.none.multiplier, 0)
        // none is the first/raw-zero case so it backs the stored preference default.
        XCTAssertEqual(VerseDelay.none.rawValue, 0)
    }

    func test_comparable_sortsByIncreasingMultiplier() {
        let unorderedDelays: [VerseDelay] = [.full, .none, .double, .half, .quarter, .threeQuarters]
        let multipliers = unorderedDelays.sorted().map(\.multiplier)

        XCTAssertEqual(multipliers, multipliers.sorted())
    }

    func test_allCases_areCappedAtDoubleDelay() {
        XCTAssertEqual(VerseDelay.allCases.last, .double)
        XCTAssertTrue(VerseDelay.allCases.allSatisfy { $0.multiplier <= 2 })
    }
}

//
//  RunsLocalizationTests.swift
//

import QuranAudio
import XCTest
@testable import NoorUI

final class RunsLocalizationTests: XCTestCase {
    func test_runsLocalizedDescription_finiteValuesFormatLocalizedNumbersWithMultiplicationSign() {
        XCTAssertEqual(Runs.finite(1).localizedDescription, "1×")
        XCTAssertEqual(Runs.finite(2).localizedDescription, "2×")
        XCTAssertEqual(Runs.finite(3).localizedDescription, "3×")
        XCTAssertEqual(Runs.finite(4).localizedDescription, "4×")
        XCTAssertEqual(Runs.finite(5).localizedDescription, "5×")
        XCTAssertEqual(Runs.finite(7).localizedDescription, "7×")
        XCTAssertEqual(Runs.finite(30).localizedDescription, "30×")
    }

    func test_runsChoices_listLoopFirstThenOneThroughOneHundred() {
        XCTAssertEqual(Runs.choices.first, .indefinite)
        XCTAssertEqual(Array(Runs.choices.dropFirst()), (1 ... 100).map(Runs.finite))
    }
}

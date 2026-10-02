//
//  AudioOptionsLocalizationTests.swift
//

import QueuePlayer
import QuranAudio
import QuranAudioKit
import XCTest

final class AudioOptionsLocalizationTests: XCTestCase {
    // MARK: - Runs

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

    // MARK: - Delays

    func test_verseDelaySorted_matchesExpectedOrder() {
        XCTAssertEqual(VerseDelay.sorted, [.none, .quarter, .half, .threeQuarters, .full, .double])
    }

    func test_repetitionDelaySorted_matchesExpectedOrder() {
        XCTAssertEqual(RepetitionDelay.sorted, [.none, .oneSecond, .twoSeconds, .threeSeconds, .fiveSeconds, .tenSeconds])
    }
}

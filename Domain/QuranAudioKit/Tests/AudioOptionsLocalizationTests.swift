//
//  AudioOptionsLocalizationTests.swift
//

import QueuePlayer
import QuranAudio
import QuranAudioKit
import XCTest

final class AudioOptionsLocalizationTests: XCTestCase {
    // MARK: - Delays

    func test_verseDelaySorted_matchesExpectedOrder() {
        XCTAssertEqual(VerseDelay.sorted, [.none, .quarter, .half, .threeQuarters, .full, .double])
    }

    func test_repetitionDelaySorted_matchesExpectedOrder() {
        XCTAssertEqual(RepetitionDelay.sorted, [.none, .oneSecond, .twoSeconds, .threeSeconds, .fiveSeconds, .tenSeconds])
    }
}

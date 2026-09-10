import Localization
import XCTest
@testable import NoorUI

final class AudioOptionsSummaryTests: XCTestCase {
    func testDefaultsHideIndicatorAndSummary() {
        let summary = AudioOptionsSummary()
        XCTAssertFalse(summary.hasNonDefaultValues)
        XCTAssertEqual(summary.text, "")
    }

    func testSpeedAloneShowsSummary() {
        for rate: Float in [0.5, 1.5] {
            let summary = AudioOptionsSummary(rate: rate)
            XCTAssertTrue(summary.hasNonDefaultValues)
            XCTAssertEqual(summary.text, PlaybackSpeed.formatted(rate))
        }
    }

    func testVerseRepetitionDoesNotRequireNonDefaultSpeed() {
        let summary = AudioOptionsSummary(verseRuns: .finite(3))
        XCTAssertTrue(summary.hasNonDefaultValues)
        XCTAssertEqual(summary.text, String(format: l("audio.summary.verse"), "×3"))
    }

    func testRangeRepetitionDoesNotRequireVerseRepetition() {
        let summary = AudioOptionsSummary(rangeRuns: .finite(2))
        XCTAssertTrue(summary.hasNonDefaultValues)
        XCTAssertEqual(summary.text, String(format: l("audio.summary.range"), "×2"))
    }

    func testEndlessRepetitionIsVisibleForEitherCount() {
        for summary in [AudioOptionsSummary(verseRuns: .indefinite), AudioOptionsSummary(rangeRuns: .indefinite)] {
            XCTAssertTrue(summary.hasNonDefaultValues)
            XCTAssertTrue(summary.text.contains("∞"))
            XCTAssertFalse(summary.text.contains("×"))
        }
    }

    func testSummaryCombinesSpeedVerseAndRangeInOrder() {
        let summary = AudioOptionsSummary(rate: 0.5, verseRuns: .finite(3), rangeRuns: .finite(2))
        XCTAssertEqual(summary.text, [
            PlaybackSpeed.formatted(0.5),
            String(format: l("audio.summary.verse"), "×3"),
            String(format: l("audio.summary.range"), "×2"),
        ].joined(separator: " · "))
    }
}

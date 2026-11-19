//
//  WordFrameProcessorTextColumnTests.swift
//

import QuranGeometry
import QuranKit
import XCTest
@testable import WordFrameService

final class WordFrameProcessorTextColumnTests: XCTestCase {
    func testShortCentredLinesDoNotPullTheColumnIn() {
        // Like a sura's last page: four full lines, one ending early, and four short centred ones.
        let full = 40 ... 1080
        let frames = lines([full, full, 120 ... 1080, full, short, full, short, short, short])

        let column = WordFrameProcessor().textColumn(frames, imageWidth: 1120) { $0 }

        XCTAssertEqual(column, 40 ... 1080)
    }

    func testAnOpeningPageHasNoColumnEvenWithAFewWideLines() {
        let wide = 100 ... 1010
        let frames = lines([short, wide, short, short, wide, short, short])

        let column = WordFrameProcessor().textColumn(frames, imageWidth: 1120) { $0 }

        XCTAssertNil(column)
    }

    // MARK: Private

    private let short = 300 ... 820

    /// One frame per line, spanning each range, stacked top to bottom.
    private func lines(_ ranges: [ClosedRange<Int>]) -> [WordFrame] {
        let verse = Quran.hafsMadani1405.firstVerse
        return ranges.enumerated().map { index, range in
            WordFrame(
                line: index + 1,
                word: Word(verse: verse, wordNumber: index + 1),
                minX: range.lowerBound,
                maxX: range.upperBound,
                minY: index * 100,
                maxY: (index + 1) * 100
            )
        }
    }
}

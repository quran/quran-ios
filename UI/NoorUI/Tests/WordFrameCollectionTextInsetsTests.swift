import QuranGeometry
import QuranKit
import SwiftUI
import XCTest
@testable import NoorUI

final class WordFrameCollectionTextInsetsTests: XCTestCase {
    func testInsetsReachTheTextInACentredImage() {
        // A 1000 x 2000 image shown at half size in content 600 wide leaves 50 points either side.
        let insets = wordFrames.textInsets(
            imageSize: CGSize(width: 1000, height: 2000),
            imageViewSize: CGSize(width: 500, height: 1000),
            contentWidth: 600,
            layoutDirection: .leftToRight
        )

        XCTAssertEqual(insets, EdgeInsets(top: 0, leading: 100, bottom: 0, trailing: 125))
    }

    func testRightToLeftSwapsLeadingAndTrailing() {
        let insets = wordFrames.textInsets(
            imageSize: CGSize(width: 1000, height: 2000),
            imageViewSize: CGSize(width: 500, height: 1000),
            contentWidth: 600,
            layoutDirection: .rightToLeft
        )

        XCTAssertEqual(insets, EdgeInsets(top: 0, leading: 125, bottom: 0, trailing: 100))
    }

    func testPagesWithoutWordFramesKeepTheHeaderInsets() {
        let insets = WordFrameCollection(frames: []).textInsets(
            imageSize: CGSize(width: 1000, height: 2000),
            imageViewSize: CGSize(width: 500, height: 1000),
            contentWidth: 600,
            layoutDirection: .leftToRight
        )

        XCTAssertNil(insets)
    }

    func testShortLinesAndOverhangsDoNotMoveTheInsets() {
        let verses = Quran.hafsMadani1405.suras[1].verses
        let lines = wordFrames.frames + [
            // A short, centred line, and a full line whose mark overhangs both margins.
            WordFrame(line: 3, word: Word(verse: verses[1], wordNumber: 1), minX: 400, maxX: 600, minY: 140, maxY: 180),
            WordFrame(line: 4, word: Word(verse: verses[1], wordNumber: 2), minX: 60, maxX: 900, minY: 190, maxY: 230),
        ]

        let insets = WordFrameCollection(frames: lines).textInsets(
            imageSize: CGSize(width: 1000, height: 2000),
            imageViewSize: CGSize(width: 500, height: 1000),
            contentWidth: 600,
            layoutDirection: .leftToRight
        )

        XCTAssertEqual(insets, EdgeInsets(top: 0, leading: 100, bottom: 0, trailing: 125))
    }

    private var wordFrames: WordFrameCollection {
        let verses = Quran.hafsMadani1405.suras[1].verses
        // Each line runs from x 100 to 850 in the image: 50 to 425 points in the image view.
        return WordFrameCollection(frames: [
            WordFrame(line: 1, word: Word(verse: verses[0], wordNumber: 1), minX: 500, maxX: 850, minY: 40, maxY: 80),
            WordFrame(line: 1, word: Word(verse: verses[0], wordNumber: 2), minX: 100, maxX: 500, minY: 40, maxY: 80),
            WordFrame(line: 2, word: Word(verse: verses[0], wordNumber: 3), minX: 100, maxX: 850, minY: 90, maxY: 130),
            WordFrame(line: 5, word: Word(verse: verses[0], wordNumber: 4), minX: 100, maxX: 850, minY: 240, maxY: 280),
        ])
    }
}

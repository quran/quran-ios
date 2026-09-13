import QuranGeometry
import QuranKit
import SwiftUI
import XCTest
@testable import NoorUI

final class ImageDecorationsLayoutTests: XCTestCase {
    func testUnhighlightedWordFramesKeepScaledGeometry() {
        let layout = makeLayout(frames: wordFrames, scale: WordFrameScale(scale: 0.5, xOffset: 10, yOffset: 20))

        XCTAssertEqual(layout.highlights.map(\.frame), [
            CGRect(x: 50, y: 40, width: 20, height: 20),
            CGRect(x: 20, y: 40, width: 30, height: 20),
            CGRect(x: 30, y: 90, width: 30, height: 20),
        ])
        XCTAssertTrue(layout.highlights.allSatisfy { $0.color == .clear })
        XCTAssertTrue(layout.drawnAyahMarkers.isEmpty)
    }

    func testResizingAndHighlightingPreserveWordFrameIdentity() {
        let frames = wordFrames
        let original = makeLayout(frames: frames, scale: WordFrameScale(scale: 1, xOffset: 0, yOffset: 0))
        let resized = makeLayout(
            frames: frames,
            scale: WordFrameScale(scale: 0.5, xOffset: 10, yOffset: 20),
            highlights: [frames.frames[0]: .yellow]
        )

        XCTAssertEqual(original.highlights.map(\.id), resized.highlights.map(\.id))
        XCTAssertEqual(resized.highlights[0].frame, CGRect(x: 50, y: 40, width: 20, height: 20))
        XCTAssertEqual(resized.highlights[0].color, .yellow)
    }

    private var wordFrames: WordFrameCollection {
        let verses = Quran.hafsMadani1405.suras[1].verses
        return WordFrameCollection(frames: [
            WordFrame(line: 2, word: Word(verse: verses[0], wordNumber: 1), minX: 80, maxX: 120, minY: 40, maxY: 80),
            WordFrame(line: 2, word: Word(verse: verses[1], wordNumber: 1), minX: 20, maxX: 80, minY: 40, maxY: 80),
            WordFrame(line: 5, word: Word(verse: verses[1], wordNumber: 2), minX: 40, maxX: 100, minY: 140, maxY: 180),
        ])
    }

    private func makeLayout(
        frames: WordFrameCollection,
        scale: WordFrameScale,
        highlights: [WordFrame: Color] = [:]
    ) -> ImageDecorationsLayout {
        ImageDecorationsLayout(
            decorations: ImageDecorations(
                suraHeaders: [],
                ayahNumbers: [],
                drawsAyahNumbersAndSuraHeaders: false,
                wordFrames: frames,
                highlights: highlights
            ),
            imageSize: CGSize(width: 200, height: 300),
            scale: scale
        )
    }
}

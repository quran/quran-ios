import QuranAnnotations
import QuranGeometry
import QuranKit
import SwiftUI
import XCTest
@testable import NoorUI

final class ImageDecorationsLayoutTests: XCTestCase {
    func testUnhighlightedPageHasNoHighlights() {
        let layout = makeLayout(scale: WordFrameScale(scale: 0.5, xOffset: 10, yOffset: 20))

        XCTAssertTrue(layout.verseHighlights.isEmpty)
        XCTAssertNil(layout.wordHighlight)
        XCTAssertTrue(layout.drawnAyahMarkers.isEmpty)
    }

    func testVerseHighlightUnitesWordFramesPerLineInScaledGeometry() {
        let layout = makeLayout(
            scale: WordFrameScale(scale: 0.5, xOffset: 10, yOffset: 20),
            verseHighlights: [verses[1]: .yellow]
        )

        XCTAssertEqual(layout.verseHighlights.map(\.id), [verses[1]])
        XCTAssertEqual(layout.verseHighlights[0].lineRects, [
            CGRect(x: 20, y: 40, width: 50, height: 20),
            CGRect(x: 30, y: 90, width: 30, height: 20),
        ])
        XCTAssertEqual(layout.verseHighlights[0].color, .yellow)
    }

    func testVerseHighlightsAreOrderedByVerse() {
        let layout = makeLayout(
            scale: WordFrameScale(scale: 1, xOffset: 0, yOffset: 0),
            verseHighlights: [verses[1]: .blue, verses[0]: .yellow]
        )

        XCTAssertEqual(layout.verseHighlights.map(\.id), [verses[0], verses[1]])
    }

    func testWordHighlightUsesTheWordFrame() {
        let layout = makeLayout(
            scale: WordFrameScale(scale: 0.5, xOffset: 10, yOffset: 20),
            wordHighlight: Word(verse: verses[1], wordNumber: 2)
        )

        XCTAssertEqual(layout.wordHighlight?.frame, CGRect(x: 30, y: 90, width: 30, height: 20))
        XCTAssertEqual(layout.wordHighlight?.color, VerseOverlays.wordHighlightColor)
    }

    private var verses: [AyahNumber] {
        Quran.hafsMadani1405.suras[1].verses
    }

    private var wordFrames: WordFrameCollection {
        WordFrameCollection(frames: [
            WordFrame(line: 2, word: Word(verse: verses[0], wordNumber: 1), minX: 120, maxX: 160, minY: 40, maxY: 80),
            WordFrame(line: 2, word: Word(verse: verses[1], wordNumber: 1), minX: 80, maxX: 120, minY: 40, maxY: 80),
            WordFrame(line: 2, word: Word(verse: verses[1], wordNumber: 1), minX: 20, maxX: 80, minY: 40, maxY: 80),
            WordFrame(line: 5, word: Word(verse: verses[1], wordNumber: 2), minX: 40, maxX: 100, minY: 140, maxY: 180),
        ])
    }

    private func makeLayout(
        scale: WordFrameScale,
        verseHighlights: [AyahNumber: Color] = [:],
        wordHighlight: Word? = nil
    ) -> ImageDecorationsLayout {
        ImageDecorationsLayout(
            decorations: ImageDecorations(
                suraHeaders: [],
                ayahNumbers: [],
                drawsAyahNumbersAndSuraHeaders: false,
                wordFrames: wordFrames,
                verseHighlights: verseHighlights,
                wordHighlight: wordHighlight
            ),
            imageSize: CGSize(width: 200, height: 300),
            scale: scale
        )
    }
}

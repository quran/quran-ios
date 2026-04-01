//
//  LinePageWordFrameAdapterTests.swift
//
//
//  Created by OpenAI Codex on 2026-03-31.
//

import LinePagePersistence
import QuranKit
import XCTest
@testable import ImageService

final class LinePageWordFrameAdapterTests: XCTestCase {
    func testAdapterCreatesStableOrderedSyntheticWordFrames() throws {
        let quran = Quran.hafsMadani1405
        let ayah1 = try XCTUnwrap(AyahNumber(quran: quran, sura: 1, ayah: 1))
        let ayah2 = try XCTUnwrap(AyahNumber(quran: quran, sura: 1, ayah: 2))

        let wordFrames = LinePageWordFrameAdapter().wordFrames(
            from: [
                .init(ayah: ayah2, line: 3, left: 0.2, right: 0.5),
                .init(ayah: ayah1, line: 0, left: 0.10, right: 0.35),
                .init(ayah: ayah1, line: 0, left: 0.60, right: 0.90),
                .init(ayah: ayah1, line: 2, left: 0.40, right: 0.80),
            ],
            quran: quran,
            lineCount: 15
        )

        let firstAyahFrames = wordFrames.wordFramesForVerse(ayah1)
        XCTAssertEqual(firstAyahFrames.map(\.word.wordNumber), [1, 2, 3])
        XCTAssertEqual(firstAyahFrames.map(\.line), [1, 1, 3])

        let firstLine = try XCTUnwrap(wordFrames.lineFramesVerVerse(ayah1).first)
        XCTAssertEqual(Set(firstLine.frames.map(\.word.verse)), [ayah1])
        XCTAssertEqual(Set(firstLine.frames.map(\.line)), [1])

        let secondAyahFrames = wordFrames.wordFramesForVerse(ayah2)
        XCTAssertEqual(secondAyahFrames.map(\.word.wordNumber), [1])
        XCTAssertEqual(secondAyahFrames.map(\.line), [4])
    }

    func testAdapterReturnsEmptyCollectionWhenThereAreNoSpans() {
        let wordFrames = LinePageWordFrameAdapter().wordFrames(
            from: [],
            quran: .hafsMadani1405,
            lineCount: 15
        )

        XCTAssertEqual(wordFrames.lines, [])
    }
}

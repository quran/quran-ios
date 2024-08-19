//
//  WordFrameTests.swift
//
//
//  Created by Mohamed Afifi on 2024-04-05.
//

import QuranGeometry
import QuranKit
import XCTest
@testable import WordFrameService

class WordFrameTests: XCTestCase {
    let word1 = Word(verse: Quran.hafsMadani1405.firstVerse, wordNumber: 1)
    let word2 = Word(verse: Quran.hafsMadani1405.firstVerse, wordNumber: 2)

    func testNonOverlappingFrames() {
        // Case 1: Non-overlapping frames
        // Before: [leftFrame]     [rightFrame]
        var leftFrame = WordFrame(line: 1, word: word1, minX: 0, maxX: 10, minY: 0, maxY: 10)
        var rightFrame = WordFrame(line: 1, word: word2, minX: 20, maxX: 30, minY: 0, maxY: 10)
        WordFrame.unionHorizontally(leftFrame: &leftFrame, rightFrame: &rightFrame)
        // After:  [leftFrame][rightFrame]

        assertFrame(leftFrame, minX: 0, maxX: 15)
        assertFrame(rightFrame, minX: 15, maxX: 30)
    }

    func testOverlappingFrames() {
        // Case 2: Overlapping frames with non-overlapping parts
        // Before: [leftFrame overlaps]
        //                   [overlaps rightFrame]
        var leftFrame = WordFrame(line: 1, word: word1, minX: 0, maxX: 20, minY: 0, maxY: 10)
        var rightFrame = WordFrame(line: 1, word: word2, minX: 15, maxX: 35, minY: 0, maxY: 10)
        WordFrame.unionHorizontally(leftFrame: &leftFrame, rightFrame: &rightFrame)
        // After:  [leftFrame][rightFrame]

        assertFrame(leftFrame, minX: 0, maxX: 15)
        assertFrame(rightFrame, minX: 15, maxX: 35)
    }
}

func assertFrame(_ frame: WordFrame, minX: Int, maxX: Int, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(frame.minX, minX, "minX")
    XCTAssertEqual(frame.maxX, maxX, "minX")
}

import SwiftUI
import XCTest
@testable import NoorUI

final class QuranHighlightShapeTests: XCTestCase {
    func testSingleLineIsOneRoundedRectangleInsetByTheVerseInset() {
        let outlines = outlines([CGRect(x: 100, y: 0, width: 200, height: 50)])

        XCTAssertEqual(outlines, [
            QuranHighlightOutline(
                corners: [CGPoint(x: 101, y: 1), CGPoint(x: 299, y: 1), CGPoint(x: 299, y: 49), CGPoint(x: 101, y: 49)],
                cornerRadius: 10
            ),
        ])
    }

    func testVerseStartingMidLineJoinsTheNextLineIntoOneOutline() {
        let outlines = outlines([
            CGRect(x: 0, y: 0, width: 300, height: 50),
            CGRect(x: 100, y: 50, width: 300, height: 50),
        ])

        XCTAssertEqual(outlines.map(\.corners), [[
            CGPoint(x: 1, y: 1), CGPoint(x: 299, y: 1),
            CGPoint(x: 299, y: 50), CGPoint(x: 399, y: 50),
            CGPoint(x: 399, y: 99), CGPoint(x: 101, y: 99),
            CGPoint(x: 101, y: 50), CGPoint(x: 1, y: 50),
        ]])
    }

    func testFullMiddleLineKeepsOnlyTheStepCorners() {
        let outlines = outlines([
            CGRect(x: 0, y: 0, width: 300, height: 50),
            CGRect(x: 0, y: 50, width: 400, height: 50),
            CGRect(x: 100, y: 100, width: 300, height: 50),
        ])

        XCTAssertEqual(outlines.map(\.corners), [[
            CGPoint(x: 1, y: 1), CGPoint(x: 299, y: 1),
            CGPoint(x: 299, y: 50), CGPoint(x: 399, y: 50),
            CGPoint(x: 399, y: 149), CGPoint(x: 101, y: 149),
            CGPoint(x: 101, y: 100), CGPoint(x: 1, y: 100),
        ]])
    }

    func testLinesThatDoNotOverlapStaySeparate() {
        let outlines = outlines([
            CGRect(x: 0, y: 0, width: 100, height: 50),
            CGRect(x: 200, y: 50, width: 200, height: 50),
        ])

        XCTAssertEqual(outlines.map(\.corners.count), [4, 4])
    }

    func testLinesOverlappingLessThanTwoCornersStaySeparate() {
        let outlines = outlines([
            CGRect(x: 0, y: 0, width: 110, height: 50),
            CGRect(x: 100, y: 50, width: 300, height: 50),
        ])

        XCTAssertEqual(outlines.map(\.corners.count), [4, 4])
    }

    func testLinesThatDoNotTouchVerticallyStaySeparate() {
        let outlines = outlines([
            CGRect(x: 0, y: 0, width: 400, height: 50),
            CGRect(x: 0, y: 70, width: 400, height: 50),
        ])

        XCTAssertEqual(outlines.map(\.corners.count), [4, 4])
    }

    func testLinesAreOrderedTopToBottom() {
        let lines = [
            CGRect(x: 100, y: 50, width: 300, height: 50),
            CGRect(x: 0, y: 0, width: 300, height: 50),
        ]

        XCTAssertEqual(outlines(lines), outlines(lines.reversed()))
    }

    func testPathFollowsTheStepBetweenLines() {
        let path = QuranHighlightShape(lineRects: [
            CGRect(x: 0, y: 0, width: 300, height: 50),
            CGRect(x: 100, y: 50, width: 300, height: 50),
        ]).path(in: .zero)

        XCTAssertTrue(path.contains(CGPoint(x: 200, y: 50)))
        XCTAssertFalse(path.contains(CGPoint(x: 350, y: 25)))
        XCTAssertFalse(path.contains(CGPoint(x: 50, y: 75)))
        XCTAssertFalse(path.contains(CGPoint(x: 2, y: 2)), "outer corners are rounded")
    }

    func testWordUsesTheWordInset() {
        let shape = QuranHighlightShape.word(CGRect(x: 0, y: 0, width: 60, height: 50))

        let bounds = shape.path(in: .zero).boundingRect
        XCTAssertEqual(bounds.minX, 1.5, accuracy: 0.001)
        XCTAssertEqual(bounds.minY, 3, accuracy: 0.001)
        XCTAssertEqual(bounds.maxX, 58.5, accuracy: 0.001)
        XCTAssertEqual(bounds.maxY, 47, accuracy: 0.001)
    }

    private func outlines(_ lineRects: [CGRect]) -> [QuranHighlightOutline] {
        QuranHighlightOutline.outlines(lineRects: lineRects, inset: QuranHighlightShape.verseInset)
    }
}

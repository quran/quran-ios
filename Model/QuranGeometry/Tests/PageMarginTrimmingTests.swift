//
//  PageMarginTrimmingTests.swift
//
//
//  Created by Claude on 2026-11-07.
//

import QuranGeometry
import XCTest

final class PageMarginTrimmingTests: XCTestCase {
    private let imageSize = CGSize(width: 1000, height: 1600)

    func test_visibleRect_trimsTheSmallerBlankOfOppositeSides() {
        // 60 blank on the left, 80 on the right; 70 above, 50 below.
        let content = CGRect(x: 60, y: 70, width: 860, height: 1480)

        let visible = PageMarginTrimming.visibleRect(imageSize: imageSize, contentFrames: [content])

        // Trims min(60, 80) - 1% padding = 50 from each side, and min(70, 50) - 16 = 34 from top and bottom.
        XCTAssertEqual(visible, CGRect(x: 50, y: 34, width: 900, height: 1532))
    }

    func test_visibleRect_coversEveryContentFrame() {
        let words = CGRect(x: 100, y: 300, width: 800, height: 1000)
        let suraHeader = CGRect(x: 100, y: 120, width: 800, height: 80)

        let visible = PageMarginTrimming.visibleRect(imageSize: imageSize, contentFrames: [words, suraHeader])

        XCTAssertTrue(visible.contains(words))
        XCTAssertTrue(visible.contains(suraHeader))
    }

    func test_visibleRect_capsTheTrimForShortCenteredPages() {
        // A short page like Al-Fatihah: a small block of centered text.
        let content = CGRect(x: 350, y: 400, width: 300, height: 400)

        let visible = PageMarginTrimming.visibleRect(imageSize: imageSize, contentFrames: [content])

        XCTAssertEqual(visible, imageSize.rect.insetBy(dx: 80, dy: 128))
    }

    func test_visibleRect_withoutContent_isTheWholeImage() {
        let visible = PageMarginTrimming.visibleRect(imageSize: imageSize, contentFrames: [])

        XCTAssertEqual(visible, imageSize.rect)
    }

    func test_scaling_fitsTheVisibleRectAndCentersIt() {
        let visible = CGRect(x: 50, y: 100, width: 900, height: 1400)
        let viewSize = CGSize(width: 500, height: 700)

        let scale = WordFrameScale.scaling(imageSize: imageSize, visibleRect: visible, into: viewSize)

        // The visible rect fits the view's height: 1400 * 0.5 = 700, and its width 450 centers in 500.
        XCTAssertEqual(scale.scale, 0.5)
        XCTAssertEqual(visible.scaled(by: scale), CGRect(x: 25, y: 0, width: 450, height: 700))
    }
}

private extension CGSize {
    var rect: CGRect { CGRect(origin: .zero, size: self) }
}

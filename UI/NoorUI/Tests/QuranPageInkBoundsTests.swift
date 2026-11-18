//
//  QuranPageInkBoundsTests.swift
//
//
//  Created by Mohamed Afifi on 2026-11-18.
//

import QuranGeometry
import UIKit
import XCTest
@testable import NoorUI

final class QuranPageInkBoundsTests: XCTestCase {
    // MARK: Internal

    func test_inkBounds_holdTheSuraFrameDrawnIntoThePage() throws {
        // Madani 1405 draws Al-Fātihah's sura frame into page 1, above the words, from x 64 to 1168, y 10 to 146.
        let image = try page1()

        let bounds = try XCTUnwrap(image.quranPageInkBounds)

        XCTAssertLessThanOrEqual(bounds.minY, 10)
        XCTAssertLessThanOrEqual(bounds.minX, 64)
        XCTAssertGreaterThanOrEqual(bounds.maxX, 1168)
    }

    func test_trimmingPage1_keepsItsSuraFrame() throws {
        // Page 1's words start below the frame and leave most of the page blank below, so trimming by the words
        // alone took the full 8% off the top and cut the frame.
        let image = try page1()
        let words = CGRect(x: 260, y: 260, width: 760, height: 720)
        let frame = CGRect(x: 64, y: 10, width: 1104, height: 136)

        let wordsOnly = PageMarginTrimming.visibleRect(imageSize: image.size, contentFrames: [words])
        let withInk = PageMarginTrimming.visibleRect(
            imageSize: image.size,
            contentFrames: [words, try XCTUnwrap(image.quranPageInkBounds)]
        )

        XCTAssertFalse(wordsOnly.contains(frame))
        XCTAssertTrue(withInk.contains(frame))
    }

    func test_inkBounds_ofABlankImage_areNil() {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 60)).image { _ in }

        XCTAssertNil(image.quranPageInkBounds)
    }

    // MARK: Private

    private func page1() throws -> UIImage {
        try XCTUnwrap(UIImage(contentsOfFile: testResourceURL("images/page001.png").path))
    }
}

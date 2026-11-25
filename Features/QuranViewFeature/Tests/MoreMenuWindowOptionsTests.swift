//
//  MoreMenuWindowOptionsTests.swift
//
//
//  Created by Mohamed Afifi on 2026-11-17.
//

import MoreMenuFeature
import XCTest
@testable import QuranViewFeature

final class MoreMenuWindowOptionsTests: XCTestCase {
    // MARK: Internal

    func test_iPadLandscape_offersTwoPagesAndKeepsRotation() {
        assertOptions(
            for: ReaderWindow(size: CGSize(width: 1194, height: 834), isRegularWidthAndHeight: true, isPhone: false),
            twoPages: .conditional,
            orientation: .conditional
        )
    }

    func test_13InchIPadPortrait_hidesTwoPagesAndKeepsRotation() {
        // Wider than 900pt, but the reader shows one page in portrait.
        assertOptions(
            for: ReaderWindow(size: CGSize(width: 1032, height: 1376), isRegularWidthAndHeight: true, isPhone: false),
            twoPages: .alwaysOff,
            orientation: .conditional
        )
    }

    func test_iPadNarrowSplit_hidesTwoPagesAndKeepsRotation() {
        // A third of an iPad in landscape has a compact width.
        assertOptions(
            for: ReaderWindow(size: CGSize(width: 375, height: 834), isRegularWidthAndHeight: false, isPhone: false),
            twoPages: .alwaysOff,
            orientation: .conditional
        )
    }

    func test_iPhoneLandscape_hidesTwoPagesAndKeepsRotation() {
        assertOptions(
            for: ReaderWindow(size: CGSize(width: 874, height: 402), isRegularWidthAndHeight: false, isPhone: true),
            twoPages: .alwaysOff,
            orientation: .conditional
        )
    }

    func test_iPhoneProMaxLandscape_offersTwoPagesAndKeepsRotation() {
        // Regular width, but compact height.
        assertOptions(
            for: ReaderWindow(size: CGSize(width: 956, height: 440), isRegularWidthAndHeight: false, isPhone: true),
            twoPages: .conditional,
            orientation: .conditional
        )
    }

    func test_iPhoneDuoFolded_hidesTwoPagesAndKeepsRotation() {
        assertOptions(
            for: ReaderWindow(size: CGSize(width: 466, height: 1010), isRegularWidthAndHeight: false, isPhone: true),
            twoPages: .alwaysOff,
            orientation: .conditional
        )
    }

    func test_iPhoneDuoUnfoldedPortrait_hidesTwoPagesAndRotation() {
        assertOptions(
            for: ReaderWindow(size: CGSize(width: 669, height: 951), isRegularWidthAndHeight: true, isPhone: true),
            twoPages: .alwaysOff,
            orientation: .alwaysOff
        )
    }

    func test_iPhoneDuoUnfoldedLandscape_offersTwoPagesAndHidesRotation() {
        assertOptions(
            for: ReaderWindow(size: CGSize(width: 951, height: 669), isRegularWidthAndHeight: true, isPhone: true),
            twoPages: .conditional,
            orientation: .alwaysOff
        )
    }

    func test_noWindow_hidesTwoPagesAndKeepsRotation() {
        assertOptions(
            for: nil,
            twoPages: .alwaysOff,
            orientation: .conditional
        )
    }

    // MARK: Private

    private func assertOptions(
        for window: ReaderWindow?,
        twoPages: ConfigState,
        orientation: ConfigState,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let options = MoreMenuWindowOptions(window: window)

        XCTAssertEqual(options.twoPages, twoPages, "two pages", file: file, line: line)
        XCTAssertEqual(options.orientation, orientation, "orientation", file: file, line: line)
    }
}

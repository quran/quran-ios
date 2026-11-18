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
            for: ReaderWindow(width: 1194, isRegularWidthAndHeight: true, isPhone: false),
            twoPages: .conditional,
            orientation: .conditional
        )
    }

    func test_iPadNarrowSplit_hidesTwoPagesAndKeepsRotation() {
        // A third of an iPad in landscape has a compact width.
        assertOptions(
            for: ReaderWindow(width: 375, isRegularWidthAndHeight: false, isPhone: false),
            twoPages: .alwaysOff,
            orientation: .conditional
        )
    }

    func test_iPhoneLandscape_hidesTwoPagesAndKeepsRotation() {
        assertOptions(
            for: ReaderWindow(width: 874, isRegularWidthAndHeight: false, isPhone: true),
            twoPages: .alwaysOff,
            orientation: .conditional
        )
    }

    func test_iPhoneProMaxLandscape_offersTwoPagesAndKeepsRotation() {
        // Regular width, but compact height.
        assertOptions(
            for: ReaderWindow(width: 956, isRegularWidthAndHeight: false, isPhone: true),
            twoPages: .conditional,
            orientation: .conditional
        )
    }

    func test_iPhoneDuoFolded_hidesTwoPagesAndKeepsRotation() {
        assertOptions(
            for: ReaderWindow(width: 466, isRegularWidthAndHeight: false, isPhone: true),
            twoPages: .alwaysOff,
            orientation: .conditional
        )
    }

    func test_iPhoneDuoUnfoldedPortrait_hidesTwoPagesAndRotation() {
        assertOptions(
            for: ReaderWindow(width: 669, isRegularWidthAndHeight: true, isPhone: true),
            twoPages: .alwaysOff,
            orientation: .alwaysOff
        )
    }

    func test_iPhoneDuoUnfoldedLandscape_offersTwoPagesAndHidesRotation() {
        assertOptions(
            for: ReaderWindow(width: 951, isRegularWidthAndHeight: true, isPhone: true),
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

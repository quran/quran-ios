//
//  TwoPagesUtilsTests.swift
//
//
//  Created by Zubair Khan on 2022-11-12.
//

import XCTest
@testable import QuranTextKit

class TwoPagesUtilsTests: XCTestCase {
    func test_hasRoomForTwoPages_usesWindowSize() {
        // Closed iPhone Duo and iPhone portrait.
        XCTAssertFalse(TwoPagesUtils.hasRoomForTwoPages(windowSize: CGSize(width: 466, height: 1010)))
        // Unfolded iPhone Duo in portrait.
        XCTAssertFalse(TwoPagesUtils.hasRoomForTwoPages(windowSize: CGSize(width: 669, height: 951)))
        XCTAssertFalse(TwoPagesUtils.hasRoomForTwoPages(windowSize: CGSize(width: 900, height: 600)))
        // Unfolded iPhone Duo in landscape.
        XCTAssertTrue(TwoPagesUtils.hasRoomForTwoPages(windowSize: CGSize(width: 951, height: 669)))
        // iPad in landscape.
        XCTAssertTrue(TwoPagesUtils.hasRoomForTwoPages(windowSize: CGSize(width: 1194, height: 834)))
    }

    func test_hasRoomForTwoPages_wideButPortrait_hasNoRoom() {
        // 13" iPad in portrait.
        XCTAssertFalse(TwoPagesUtils.hasRoomForTwoPages(windowSize: CGSize(width: 1032, height: 1376)))
    }

    func test_isEnabled_preferenceOnInAWideWindow_isOn() {
        // Unfolded iPhone Duo in landscape.
        XCTAssertTrue(TwoPagesUtils.isEnabled(preference: true, windowSize: CGSize(width: 951, height: 669)))
    }

    func test_isEnabled_preferenceOnInANarrowWindow_isOff() {
        // Unfolded iPhone Duo in portrait.
        XCTAssertFalse(TwoPagesUtils.isEnabled(preference: true, windowSize: CGSize(width: 669, height: 951)))
    }

    func test_isEnabled_preferenceOffInAWideWindow_isOff() {
        // iPad in landscape.
        XCTAssertFalse(TwoPagesUtils.isEnabled(preference: false, windowSize: CGSize(width: 1194, height: 834)))
    }

    func test_isEnabled_needsMoreThan900Points() {
        XCTAssertFalse(TwoPagesUtils.isEnabled(preference: true, windowSize: CGSize(width: 900, height: 600)))
        XCTAssertTrue(TwoPagesUtils.isEnabled(preference: true, windowSize: CGSize(width: 901, height: 600)))
    }
}

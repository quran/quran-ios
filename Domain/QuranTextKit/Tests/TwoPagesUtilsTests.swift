//
//  TwoPagesUtilsTests.swift
//
//
//  Created by Zubair Khan on 2022-11-12.
//

import XCTest
@testable import QuranTextKit

class TwoPagesUtilsTests: XCTestCase {
    func test_hasEnoughHorizontalSpace_usesWindowWidth() {
        // Closed iPhone Duo and iPhone portrait.
        XCTAssertFalse(TwoPagesUtils.hasEnoughHorizontalSpace(windowWidth: 466))
        // Unfolded iPhone Duo in portrait.
        XCTAssertFalse(TwoPagesUtils.hasEnoughHorizontalSpace(windowWidth: 669))
        XCTAssertFalse(TwoPagesUtils.hasEnoughHorizontalSpace(windowWidth: 900))
        // Unfolded iPhone Duo in landscape.
        XCTAssertTrue(TwoPagesUtils.hasEnoughHorizontalSpace(windowWidth: 951))
        // iPad in landscape.
        XCTAssertTrue(TwoPagesUtils.hasEnoughHorizontalSpace(windowWidth: 1194))
    }

    func test_isEnabled_preferenceOnInAWideWindow_isOn() {
        // Unfolded iPhone Duo in landscape.
        XCTAssertTrue(TwoPagesUtils.isEnabled(preference: true, windowWidth: 951))
    }

    func test_isEnabled_preferenceOnInANarrowWindow_isOff() {
        // Unfolded iPhone Duo in portrait.
        XCTAssertFalse(TwoPagesUtils.isEnabled(preference: true, windowWidth: 669))
    }

    func test_isEnabled_preferenceOffInAWideWindow_isOff() {
        // iPad in landscape.
        XCTAssertFalse(TwoPagesUtils.isEnabled(preference: false, windowWidth: 1194))
    }

    func test_isEnabled_needsMoreThan900Points() {
        XCTAssertFalse(TwoPagesUtils.isEnabled(preference: true, windowWidth: 900))
        XCTAssertTrue(TwoPagesUtils.isEnabled(preference: true, windowWidth: 901))
    }
}

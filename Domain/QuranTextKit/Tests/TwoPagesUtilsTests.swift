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

    func test_isEnabled_withoutPreference_followsSizeClasses() {
        XCTAssertTrue(TwoPagesUtils.isEnabled(preference: nil, isRegularWidthAndHeight: true))
        XCTAssertFalse(TwoPagesUtils.isEnabled(preference: nil, isRegularWidthAndHeight: false))
    }

    func test_isEnabled_withPreference_ignoresSizeClasses() {
        XCTAssertTrue(TwoPagesUtils.isEnabled(preference: true, isRegularWidthAndHeight: false))
        XCTAssertFalse(TwoPagesUtils.isEnabled(preference: false, isRegularWidthAndHeight: true))
    }
}

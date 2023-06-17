//
//  TwoPagesUtilsTests.swift
//
//
//  Created by Zubair Khan on 2022-11-12.
//

import XCTest
@testable import QuranTextKit

class TwoPagesUtilsTests: XCTestCase {
    func testHasEnoughHorizontalSpace() throws {
        let hasEnoughSpace = TwoPagesUtils.hasEnoughHorizontalSpace()
        if UIScreen.main.bounds.width > 900 {
            XCTAssertTrue(hasEnoughSpace)
        } else {
            XCTAssertFalse(hasEnoughSpace)
        }
    }
}

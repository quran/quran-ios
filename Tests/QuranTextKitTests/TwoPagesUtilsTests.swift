//
//  TwoPagesUtilsTests.swift
//
//
//  Created by Zubair Khan on 2022-11-12.
//

@testable import QuranTextKit
import XCTest

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

//
//  AudioRepeatSectionTitleTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import XCTest
@testable import NoorUI

final class AudioRepeatSectionTitleTests: XCTestCase {
    func testDropsTrailingColon() {
        XCTAssertEqual("Play each verse:".droppingTrailingLabelPunctuation(), "Play each verse")
        XCTAssertEqual("تشغيل كل آية:".droppingTrailingLabelPunctuation(), "تشغيل كل آية")
    }

    func testDropsSpaceBeforeTrailingColon() {
        XCTAssertEqual("Écouter chaque Aya :".droppingTrailingLabelPunctuation(), "Écouter chaque Aya")
    }

    func testDropsTrailingFullWidthPunctuation() {
        XCTAssertEqual("听听每一段经文。".droppingTrailingLabelPunctuation(), "听听每一段经文")
        XCTAssertEqual("听听这组阿亚特：".droppingTrailingLabelPunctuation(), "听听这组阿亚特")
    }

    func testKeepsPunctuationInsideTheTitle() {
        XCTAssertEqual("Вос-ти каждый аят:".droppingTrailingLabelPunctuation(), "Вос-ти каждый аят")
        XCTAssertEqual("A: b.".droppingTrailingLabelPunctuation(), "A: b")
    }

    func testKeepsTitleWithoutTrailingPunctuation() {
        XCTAssertEqual("Her âyeti".droppingTrailingLabelPunctuation(), "Her âyeti")
    }
}

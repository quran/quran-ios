//
//  AyahWheelPickerModelTests.swift
//

import QuranKit
import XCTest
@testable import AdvancedAudioOptionsFeature

final class AyahWheelPickerModelTests: XCTestCase {
    func test_selectingShorterSura_clampsAyahToNewSuraEnd() {
        let alBaqarah = quran.suras[1]
        let alFatihah = quran.suras[0]
        let sut = AyahWheelPickerModel(selection: alBaqarah.lastVerse, minimum: nil)

        let selection = sut.selecting(sura: alFatihah)

        XCTAssertEqual(selection, alFatihah.lastVerse)
    }

    func test_selectingLongerSura_retainsAyahNumber() {
        let alFatihah = quran.suras[0]
        let alBaqarah = quran.suras[1]
        let sut = AyahWheelPickerModel(selection: alFatihah.lastVerse, minimum: nil)

        let selection = sut.selecting(sura: alBaqarah)

        XCTAssertEqual(selection, alBaqarah.verses[6])
    }

    func test_toSuras_excludeSurasBeforeFrom() {
        let from = quran.suras[1].verses[99]
        let selection = quran.suras[2].firstVerse
        let sut = AyahWheelPickerModel(selection: selection, minimum: from)

        XCTAssertEqual(sut.suras.first, from.sura)
        XCTAssertFalse(sut.suras.contains(quran.suras[0]))
    }

    func test_toAyahs_excludeAyahsBeforeFrom_inSameSura() {
        let sura = quran.suras[1]
        let from = sura.verses[99]
        let sut = AyahWheelPickerModel(selection: from, minimum: from)

        XCTAssertEqual(sut.ayahs.first, from)
        XCTAssertFalse(sut.ayahs.contains(sura.verses[98]))
    }

    func test_selectingFromSura_clampsRetainedAyahToMinimum() {
        let from = quran.suras[1].verses[99]
        let laterSura = quran.suras[2]
        let sut = AyahWheelPickerModel(selection: laterSura.firstVerse, minimum: from)

        let selection = sut.selecting(sura: from.sura)

        XCTAssertEqual(selection, from)
    }

    private let quran = Quran.hafsMadani1405
}

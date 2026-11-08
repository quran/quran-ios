//
//  AyahRangeLocalizationTests.swift
//

import QuranKit
import XCTest
@testable import QuranLocalization

final class AyahRangeLocalizationTests: XCTestCase {
    // MARK: Internal

    func test_sameSuraRange_writesTheEndAsItsAyahNumber() {
        let range = baqarah.verses[0] ... baqarah.verses[9]

        XCTAssertEqual(range.localizedName(language: .english, locale: english), "Al-Baqarah 2:1–10")
        XCTAssertEqual(range.localizedAccessibilityName(language: .english), "Al-Baqarah, Ayahs 1 to 10")
    }

    func test_crossSuraRange_writesBothReferences() {
        let range = baqarah.lastVerse ... imran.verses[9]

        XCTAssertEqual(range.localizedName(language: .english, locale: english), "Al-Baqarah 2:286 – Āli-ʿImrān 3:10")
        XCTAssertEqual(
            range.localizedAccessibilityName(language: .english),
            "Al-Baqarah, Ayah 286 to Āli-ʿImrān, Ayah 10"
        )
    }

    func test_singleAyahRange_writesOneReference() {
        let ayah = baqarah.verses[254]

        XCTAssertEqual((ayah ... ayah).localizedName(language: .english, locale: english), "Al-Baqarah 2:255")
        XCTAssertEqual((ayah ... ayah).localizedAccessibilityName(language: .english), "Al-Baqarah, Ayah 255")
    }

    func test_wholeSuraRange_namesOnlyTheSura() {
        let range = baqarah.firstVerse ... baqarah.lastVerse

        XCTAssertEqual(range.localizedName(language: .english, locale: english), "Al-Baqarah")
        XCTAssertEqual(range.localizedAccessibilityName(language: .english), "Al-Baqarah")
        XCTAssertNil((baqarah.firstVerse ... baqarah.verses[284]).wholeSura)
    }

    func test_arabicRange_isolatesEachCoordinateRunLeftToRight() {
        let sameSura = baqarah.verses[0] ... baqarah.verses[9]
        let crossSura = baqarah.lastVerse ... imran.verses[9]
        let baqarahName = baqarah.localizedName(language: .arabic)
        let imranName = imran.localizedName(language: .arabic)

        XCTAssertEqual(
            sameSura.localizedName(language: .arabic, locale: arabic),
            "\(baqarahName) \u{2066}٢:١–١٠\u{2069}"
        )
        // Foundation's format also isolates each right-to-left reference (FSI…PDI).
        XCTAssertEqual(
            crossSura.localizedName(language: .arabic, locale: arabic),
            "\u{2068}\(baqarahName) \u{2066}٢:٢٨٦\u{2069}\u{2069} – \u{2068}\(imranName) \u{2066}٣:١٠\u{2069}\u{2069}"
        )
    }

    // MARK: Private

    private let baqarah = Quran.hafsMadani1405.suras[1]
    private let imran = Quran.hafsMadani1405.suras[2]
    private let english = Locale(identifier: "en-CA")
    private let arabic = Locale(identifier: "ar-SA")
}

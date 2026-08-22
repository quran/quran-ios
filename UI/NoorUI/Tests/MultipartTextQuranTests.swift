//
//  MultipartTextQuranTests.swift
//

import QuranKit
import QuranLocalization
import QuranText
import XCTest
@testable import NoorUI

final class MultipartTextQuranTests: XCTestCase {
    func test_suraReference_inNonArabicLocale_usesLocalizedNameAndDecoratedGlyph() {
        let text: MultipartText = "\(sura: sura)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) \u{E905}")
    }

    func test_suraReference_inArabicLocale_usesOnlyDecoratedGlyph() {
        let text: MultipartText = "\(sura: sura)"

        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905}")
    }

    func test_suraReference_inNonArabicRightToLeftLocale_keepsLocalizedName() {
        let text: MultipartText = "\(sura: sura)"

        XCTAssertEqual(text.rawValue(locale: Locale(identifier: "fa-IR")), "\(sura.localizedName()) \u{E905}")
    }

    func test_indoPakSuraReference_usesArabicTextInsteadOfDecoratedGlyph() {
        let sura = Quran.hafsIndoPak.suras[1]
        let text: MultipartText = "\(sura: sura)"

        XCTAssertEqual(
            text.rawValue(locale: english),
            "\(sura.localizedName()) \(sura.localizedName(language: .arabic))"
        )
        XCTAssertEqual(text.rawValue(locale: arabic), sura.localizedName(language: .arabic))
    }

    func test_indoPakSuraReference_usesReadingSpecificArabicName() {
        let sura = Quran.hafsIndoPak.suras[16]
        let text: MultipartText = "\(sura: sura)"

        XCTAssertEqual(text.rawValue(locale: english), "Banī Isrā’īl بَنِي إِسْرَائِيل")
        XCTAssertEqual(text.rawValue(locale: arabic), "بَنِي إِسْرَائِيل")
    }

    func test_ayahReference_inNonArabicLocale_usesCanonicalReference() {
        let text: MultipartText = "\(ayah: ayah)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) \u{E905} · 2:255")
    }

    func test_ayahReference_inArabicLocale_usesGlyphAndLocalizedCoordinate() {
        let text: MultipartText = "\(ayah: ayah)"

        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905} · ٢:٢٥٥")
    }

    func test_singleAyahRange_usesStartReference() {
        let text: MultipartText = "\(ayahRange: ayah ... ayah)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) \u{E905} · 2:255")
    }

    func test_sameSuraAyahRange_usesEndCoordinate() {
        let end = sura.verses[255]
        let text: MultipartText = "\(ayahRange: ayah ... end)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) \u{E905} · 2:255 - 2:256")
        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905} · ٢:٢٥٥ - ٢:٢٥٦")
    }

    func test_crossSuraAyahRange_usesBothReferences() {
        let start = Quran.hafsMadani1405.suras[0].verses[6]
        let end = Quran.hafsMadani1405.suras[1].verses[0]
        let text: MultipartText = "\(ayahRange: start ... end)"

        XCTAssertEqual(
            text.rawValue(locale: english),
            "\(start.sura.localizedName()) \u{E904} · 1:7 - \(end.sura.localizedName()) \u{E905} · 2:1"
        )
    }

    func test_references_useSemanticAccessibilityText() {
        let suraText: MultipartText = "\(sura: sura)"
        let ayahText: MultipartText = "\(ayah: ayah)"

        XCTAssertEqual(suraText.accessibilityText, sura.localizedName())
        XCTAssertEqual(ayahText.accessibilityText, ayah.localizedName)
    }

    func test_ayahRange_usesSemanticAccessibilityText() {
        let end = sura.verses[255]
        let text: MultipartText = "\(ayahRange: ayah ... end)"

        XCTAssertEqual(text.accessibilityText, "\(ayah.localizedName) - \(end.localizedCoordinate())")
    }

    func test_quranText_preservesText() {
        let quranText = QuranText("Quran text")
        let text: MultipartText = "\(quran: quranText, font: .indoPak)"

        XCTAssertEqual(text.rawValue, "Quran text")
    }

    func test_quranText_storesFontAndFindsEveryAyahMarker() throws {
        let quranText = QuranText("First ١ second ٢٣")
        let text: MultipartText = "\(quran: quranText, font: .indoPak)"

        let quranPart = text.parts.first {
            if case .quran = $0 {
                return true
            }
            return false
        }
        guard case .quran(_, let font, _, _, _) = try XCTUnwrap(quranPart) else {
            return XCTFail("Expected Quran text part")
        }

        XCTAssertEqual(font, .indoPak)
        XCTAssertEqual(quranText.ayahMarkerRanges.map { String(quranText.text[$0]) }, ["١", "٢٣"])
    }

    func test_highlighting_preservesText() {
        let value = "Highlighted text"
        let range = value.startIndex ..< value.endIndex
        let text: MultipartText = "\(value, highlighting: [HighlightingRange(range, fontWeight: .heavy)])"

        XCTAssertEqual(text.rawValue, value)
    }

    private let sura = Quran.hafsMadani1405.suras[1]
    private let ayah = Quran.hafsMadani1405.suras[1].verses[254]
    private let english = Locale(identifier: "en-CA")
    private let arabic = Locale(identifier: "ar-SA")
}

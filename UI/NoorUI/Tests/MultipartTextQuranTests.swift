//
//  MultipartTextQuranTests.swift
//

import QuranKit
import QuranLocalization
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

    func test_ayahReference_inNonArabicLocale_usesCanonicalReference() {
        let text: MultipartText = "\(ayah: ayah)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) \u{E905} · 2:255")
    }

    func test_ayahReference_inArabicLocale_usesGlyphAndLocalizedCoordinate() {
        let text: MultipartText = "\(ayah: ayah)"

        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905} · ٢:٢٥٥")
    }

    func test_references_useSemanticAccessibilityText() {
        let suraText: MultipartText = "\(sura: sura)"
        let ayahText: MultipartText = "\(ayah: ayah)"

        XCTAssertEqual(suraText.accessibilityText, sura.localizedName())
        XCTAssertEqual(ayahText.accessibilityText, ayah.localizedName)
    }

    func test_quranText_preservesText() {
        let quranText = "Quran text"
        let text: MultipartText = "\(quran: quranText)"

        XCTAssertEqual(text.rawValue, "Quran text")
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

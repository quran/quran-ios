//
//  MultipartTextQuranTests.swift
//

import QuranKit
import QuranLocalization
import XCTest
@testable import NoorUI

final class MultipartTextQuranTests: XCTestCase {
    func test_suraReference_usesLocalizedNameAndDecoratedGlyph() {
        let text: MultipartText = "\(sura: sura)"

        XCTAssertEqual(text.rawValue, "\(sura.localizedName()) \u{E905}")
    }

    func test_numberedSuraReference_includesSuraNumber() {
        let text: MultipartText = "\(sura: sura, format: .numbered)"

        XCTAssertEqual(text.rawValue, "\(sura.localizedName(withNumber: true)) \u{E905}")
    }

    func test_ayahReference_usesLocalizedNameAndDecoratedSuraGlyph() {
        let text: MultipartText = "\(ayah: ayah)"

        XCTAssertEqual(text.rawValue, "\(ayah.localizedName) \u{E905}")
    }

    func test_numberedSuraAyahReference_includesSuraNumber() {
        let text: MultipartText = "\(ayah: ayah, format: .numberedSura)"

        XCTAssertEqual(text.rawValue, "\(ayah.localizedNameWithSuraNumber) \u{E905}")
    }

    func test_compactAyahReference_usesSuraAndAyahNumbers() {
        let text: MultipartText = "\(ayah: ayah, format: .compact)"

        XCTAssertEqual(
            text.rawValue,
            "\(ayah.localizedCompactName) \u{E905}"
        )
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
}

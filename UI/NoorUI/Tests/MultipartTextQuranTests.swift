//
//  MultipartTextQuranTests.swift
//

import NoorFont
import QuranKit
import QuranLocalization
import QuranText
import UIKit
import XCTest
@testable import NoorUI

final class MultipartTextQuranTests: XCTestCase {
    func test_suraReference_inNonArabicLocale_usesLocalizedNameAndDecoratedGlyph() {
        let text: MultipartText = "\(sura: sura)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) \u{E905}")
    }

    @MainActor
    func test_emphasizedSuraReference_preservesDecorationAndAccessibility() throws {
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
        let regular: MultipartText = "\(sura: sura)"
        let emphasized: MultipartText = "\(sura: sura, emphasizingSura: true)"
        let regularText = regular.attributedString(ofSize: .body)
        let emphasizedText = emphasized.attributedString(ofSize: .body)
        let regularFont = try XCTUnwrap(regularText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        let emphasizedFont = try XCTUnwrap(emphasizedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)

        XCTAssertFalse(regularFont.fontDescriptor.symbolicTraits.contains(.traitBold))
        XCTAssertTrue(emphasizedFont.fontDescriptor.symbolicTraits.contains(.traitBold))
        XCTAssertEqual(emphasizedText.string, regularText.string)
        XCTAssertEqual(emphasized.rawValue(locale: arabic), regular.rawValue(locale: arabic))
        XCTAssertEqual(emphasized.accessibilityText, regular.accessibilityText)
    }

    @MainActor
    func test_suraReference_withTextStyle_usesOnlyLocalizedName() {
        let text: MultipartText = "\(sura: sura, nameStyle: .text)"

        XCTAssertEqual(text.rawValue(locale: english), sura.localizedName())
        XCTAssertEqual(text.attributedString(ofSize: .body).string, sura.localizedName())
        XCTAssertEqual(text.accessibilityText, sura.localizedName())
    }

    func test_indoPakSuraReference_withTextStyle_omitsAdditionalArabicName() {
        let sura = Quran.hafsIndoPak.suras[1]
        let text: MultipartText = "\(sura: sura, nameStyle: .text)"

        XCTAssertEqual(text.rawValue(locale: english), sura.localizedName())
        XCTAssertEqual(text.rawValue(locale: arabic), sura.localizedName(language: .arabic))
    }

    func test_compactSuraReference_usesLocalizedTextInEnglishAndDecorationInArabic() {
        let text: MultipartText = "\(sura: sura, nameStyle: .compact)"

        XCTAssertEqual(text.rawValue(locale: english), sura.localizedName())
        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905}")
        XCTAssertEqual(text.accessibilityText, sura.localizedName())
    }

    func test_compactAyahReference_keepsLocalizedCoordinates() {
        let text: MultipartText = "\(ayah: ayah, nameStyle: .compact)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) · 2:255")
        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905} · ٢:٢٥٥")
        XCTAssertEqual(text.accessibilityText, ayah.localizedName)
    }

    func test_compactSuraReference_inNonArabicRightToLeftLocale_usesLocalizedText() {
        let text: MultipartText = "\(sura: sura, nameStyle: .compact)"

        XCTAssertEqual(text.rawValue(locale: Locale(identifier: "fa-IR")), sura.localizedName())
    }

    func test_compactIndoPakSuraReference_usesReadingSpecificArabicName() {
        let sura = Quran.hafsIndoPak.suras[16]
        let text: MultipartText = "\(sura: sura, nameStyle: .compact)"

        XCTAssertEqual(text.rawValue(locale: english), "Banī Isrā’īl")
        XCTAssertEqual(text.rawValue(locale: arabic), "بَنِي إِسْرَائِيل")
    }

    @MainActor
    func test_nameStyles_useRegularFontOnlyForTextInArabic() throws {
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
        let cases: [(SuraNameStyle, String, String)] = [
            (.standard, "\u{E905}", "icomoon"),
            (.text, sura.localizedName(language: .arabic), UIFont.preferredFont(forTextStyle: .body).fontName),
            (.compact, "\u{E905}", "icomoon"),
        ]
        for (style, expectedName, expectedFont) in cases {
            let reference = QuranReference.sura(sura, nameStyle: style)
            let attributed = reference.attributedString(size: .body, locale: arabic)
            let font = try XCTUnwrap(attributed.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)

            XCTAssertEqual(attributed.string, expectedName, "\(style)")
            XCTAssertEqual(font.fontName, expectedFont, "\(style)")
        }
    }

    @MainActor
    func test_compactReferences_preserveUIKitRendering() {
        let suraText: MultipartText = "\(sura: sura, nameStyle: .compact)"
        let ayahText: MultipartText = "\(ayah: ayah, nameStyle: .compact)"

        XCTAssertEqual(suraText.attributedString(ofSize: .body).string, suraText.rawValue)
        XCTAssertEqual(ayahText.attributedString(ofSize: .body).string, ayahText.rawValue)
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

    func test_ayahReference_withTextStyle_keepsLocalizedNameAndCoordinate() {
        let text: MultipartText = "\(ayah: ayah, nameStyle: .text)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) · 2:255")
        XCTAssertEqual(text.accessibilityText, ayah.localizedName)
    }

    func test_ayahReference_withTextStyle_inArabicLocale_keepsPlainArabicName() {
        let text: MultipartText = "\(ayah: ayah, nameStyle: .text)"

        XCTAssertEqual(text.rawValue(locale: arabic), "\(sura.localizedName(language: .arabic)) · ٢:٢٥٥")
    }

    func test_indoPakAyahReference_withTextStyle_omitsAdditionalArabicName() {
        let ayah = Quran.hafsIndoPak.suras[1].verses[254]
        let text: MultipartText = "\(ayah: ayah, nameStyle: .text)"

        XCTAssertEqual(text.rawValue(locale: english), "\(ayah.sura.localizedName()) · 2:255")
    }

    @MainActor
    func test_ayahReference_withTextStyle_preservesUIKitRendering() {
        let text: MultipartText = "\(ayah: ayah, emphasizingSura: true, nameStyle: .text)"

        XCTAssertEqual(text.attributedString(ofSize: .body).string, text.rawValue)
        XCTAssertFalse(text.attributedString(ofSize: .body).string.contains("\u{E905}"))
        XCTAssertEqual(
            QuranReference.ayah(ayah, nameStyle: .text).attributedString(size: .body, locale: arabic).string,
            text.rawValue(locale: arabic)
        )
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

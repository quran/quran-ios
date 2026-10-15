//
//  MultipartTextQuranTests.swift
//

import Localization
import NoorFont
import QuranKit
import QuranLocalization
import QuranText
import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

final class MultipartTextQuranTests: XCTestCase {
    override func setUp() {
        super.setUp()
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
    }

    // MARK: Standard (default) references

    func test_suraReference_inNonArabicLocale_usesOnlyLocalizedName() {
        let text: MultipartText = "\(sura: sura)"

        XCTAssertEqual(text.rawValue(locale: english), sura.localizedName())
    }

    @MainActor
    func test_suraReference_inArabicLocale_usesOnlyDecoratedGlyph() throws {
        let text: MultipartText = "\(sura: sura)"
        let attributed = QuranReference.sura(sura).attributedString(size: .body, locale: arabic)
        let font = try XCTUnwrap(attributed.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)

        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905}")
        XCTAssertEqual(font.fontName, "icomoon")
    }

    func test_suraReference_inNonArabicRightToLeftLocale_usesOnlyLocalizedName() {
        let text: MultipartText = "\(sura: sura)"

        XCTAssertEqual(text.rawValue(locale: Locale(identifier: "fa-IR")), sura.localizedName())
    }

    @MainActor
    func test_indoPakSuraReference_usesReadingSpecificName() throws {
        let sura = Quran.hafsIndoPak.suras[16]
        let text: MultipartText = "\(sura: sura)"
        let attributed = QuranReference.sura(sura).attributedString(size: .body, locale: arabic)
        let font = try XCTUnwrap(attributed.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)

        XCTAssertEqual(text.rawValue(locale: english), "Banī Isrā’īl")
        XCTAssertEqual(text.rawValue(locale: arabic), "بَنِي إِسْرَائِيل")
        XCTAssertEqual(font.fontName, MultipartText.FontSize.body.quranUIFont(.indoPak).fontName)
    }

    func test_ayahReference_inNonArabicLocale_usesLocalizedNameAndCoordinate() {
        let text: MultipartText = "\(ayah: ayah)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) · 2:255")
    }

    func test_ayahReference_inArabicLocale_usesGlyphAndLocalizedCoordinate() {
        let text: MultipartText = "\(ayah: ayah)"

        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905} · ٢:٢٥٥")
    }

    @MainActor
    func test_references_attributedStringMatchesRawValue() {
        for style in [SuraNameStyle.standard, .decorated, .text] {
            let suraText: MultipartText = "\(sura: sura, nameStyle: style)"
            let ayahText: MultipartText = "\(ayah: ayah, nameStyle: style)"

            for locale in [english, arabic] {
                XCTAssertEqual(
                    QuranReference.sura(sura, nameStyle: style).attributedString(size: .body, locale: locale).string,
                    suraText.rawValue(locale: locale),
                    "\(style) \(locale.identifier)"
                )
                XCTAssertEqual(
                    QuranReference.ayah(ayah, nameStyle: style).attributedString(size: .body, locale: locale).string,
                    ayahText.rawValue(locale: locale),
                    "\(style) \(locale.identifier)"
                )
            }
        }
    }

    @MainActor
    func test_emphasizedSuraReference_drawsOnlyLocalizedNameHeavy() throws {
        let cases: [(SuraNameStyle, Locale)] = [(.standard, english), (.text, arabic)]
        for (style, locale) in cases {
            let reference = QuranReference.sura(sura, nameStyle: style)
            let regular = reference.attributedString(size: .body, locale: locale)
            let emphasized = reference.attributedString(size: .body, locale: locale, emphasizesSura: true)
            let regularFont = try XCTUnwrap(regular.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
            let emphasizedFont = try XCTUnwrap(emphasized.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)

            XCTAssertFalse(regularFont.fontDescriptor.symbolicTraits.contains(.traitBold), "\(style)")
            XCTAssertTrue(emphasizedFont.fontDescriptor.symbolicTraits.contains(.traitBold), "\(style)")
            XCTAssertEqual(emphasized.string, regular.string, "\(style)")
        }

        let glyph = QuranReference.sura(sura).attributedString(size: .body, locale: arabic, emphasizesSura: true)
        let glyphFont = try XCTUnwrap(glyph.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        XCTAssertEqual(glyph.string, "\u{E905}")
        XCTAssertEqual(glyphFont.fontName, "icomoon")
    }

    // MARK: Text references

    @MainActor
    func test_textReferences_inArabicLocale_usePlainArabicNameInRegularFont() {
        let plainFont = UIFont.preferredFont(forTextStyle: .body).fontName
        let references = [QuranReference.sura(sura, nameStyle: .text), QuranReference.ayah(ayah, nameStyle: .text)]
        for reference in references {
            let attributed = reference.attributedString(size: .body, locale: arabic)
            var fonts = Set<String>()
            attributed.enumerateAttribute(.font, in: NSRange(location: 0, length: attributed.length)) { value, _, _ in
                if let font = value as? UIFont {
                    fonts.insert(font.fontName)
                }
            }

            XCTAssertEqual(fonts, [plainFont], "\(reference)")
            XCTAssertFalse(containsDecoratedGlyph(attributed.string), "\(reference)")
        }
    }

    func test_textReferences_keepLocalizedNameInEveryLocale() {
        let suraText: MultipartText = "\(sura: sura, nameStyle: .text)"
        let ayahText: MultipartText = "\(ayah: ayah, nameStyle: .text)"

        XCTAssertEqual(suraText.rawValue(locale: english), sura.localizedName())
        XCTAssertEqual(suraText.rawValue(locale: arabic), sura.localizedName(language: .arabic))
        XCTAssertEqual(ayahText.rawValue(locale: english), "\(sura.localizedName()) · 2:255")
        XCTAssertEqual(ayahText.rawValue(locale: arabic), "\(sura.localizedName(language: .arabic)) · ٢:٢٥٥")
    }

    func test_indoPakTextReference_omitsAdditionalArabicName() {
        let sura = Quran.hafsIndoPak.suras[16]
        let text: MultipartText = "\(sura: sura, nameStyle: .text)"

        XCTAssertEqual(text.rawValue(locale: english), "Banī Isrā’īl")
        XCTAssertEqual(text.rawValue(locale: arabic), "بَنِي إِسْرَائِيل")
    }

    // MARK: Decorated references

    @MainActor
    func test_decoratedSuraReference_inArabicLocale_usesOnlyGlyphInSuraNameFont() throws {
        let text: MultipartText = "\(sura: sura, nameStyle: .decorated)"
        let attributed = QuranReference.sura(sura, nameStyle: .decorated).attributedString(size: .body, locale: arabic)
        let font = try XCTUnwrap(attributed.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)

        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905}")
        XCTAssertEqual(font.fontName, "icomoon")
    }

    func test_decoratedSuraReference_inNonArabicLocale_usesLocalizedNameAndDecoratedGlyph() {
        let text: MultipartText = "\(sura: sura, nameStyle: .decorated)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) \u{E905}")
    }

    func test_decoratedSuraReference_inNonArabicRightToLeftLocale_keepsLocalizedName() {
        let text: MultipartText = "\(sura: sura, nameStyle: .decorated)"

        XCTAssertEqual(text.rawValue(locale: Locale(identifier: "fa-IR")), "\(sura.localizedName()) \u{E905}")
    }

    func test_decoratedIndoPakSuraReference_usesReadingSpecificArabicName() {
        let sura = Quran.hafsIndoPak.suras[16]
        let text: MultipartText = "\(sura: sura, nameStyle: .decorated)"

        XCTAssertEqual(text.rawValue(locale: english), "Banī Isrā’īl بَنِي إِسْرَائِيل")
        XCTAssertEqual(text.rawValue(locale: arabic), "بَنِي إِسْرَائِيل")
    }

    func test_decoratedAyahReference_inNonArabicLocale_usesCanonicalReference() {
        let text: MultipartText = "\(ayah: ayah, nameStyle: .decorated)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) \u{E905} · 2:255")
    }

    func test_decoratedAyahReference_inArabicLocale_usesGlyphAndLocalizedCoordinate() {
        let text: MultipartText = "\(ayah: ayah, nameStyle: .decorated)"

        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905} · ٢:٢٥٥")
    }

    // MARK: Ranges

    func test_singleAyahRange_usesStartReference() {
        let text: MultipartText = "\(ayahRange: ayah ... ayah)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) · 2:255")
    }

    func test_sameSuraAyahRange_usesEndCoordinate() {
        let end = sura.verses[255]
        let text: MultipartText = "\(ayahRange: ayah ... end)"

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) · 2:255 - 2:256")
        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905} · ٢:٢٥٥ - ٢:٢٥٦")
    }

    func test_crossSuraAyahRange_usesBothReferences() {
        let start = Quran.hafsMadani1405.suras[0].verses[6]
        let end = Quran.hafsMadani1405.suras[1].verses[0]
        let text: MultipartText = "\(ayahRange: start ... end)"

        XCTAssertEqual(
            text.rawValue(locale: english),
            "\(start.sura.localizedName()) · 1:7 - \(end.sura.localizedName()) · 2:1"
        )
    }

    func test_ayahRange_usesEachLanguagesRangeFormat() {
        let range = ayah ... sura.verses[255]

        XCTAssertEqual(
            MultipartText.ayahRange(range, language: .english).rawValue(locale: english),
            "\(sura.localizedName()) · 2:255 - 2:256"
        )
        XCTAssertEqual(
            MultipartText.ayahRange(range, language: .arabic).rawValue(locale: arabic),
            "\u{E905} · ٢:٢٥٥ - ٢:٢٥٦"
        )
        XCTAssertEqual(
            MultipartText.ayahRange(range, language: .chinese).rawValue(locale: chinese),
            "\(sura.localizedName()) · 2:255至2:256"
        )
    }

    func test_ayahRanges_separatesRangesWithTheListSeparator() {
        let other = Quran.hafsMadani1405.suras[2].verses[17]
        let text: MultipartText = "\(ayahRanges: [ayah ... sura.verses[255], other ... other])"

        XCTAssertEqual(text.rawValue(locale: english), "Al-Baqarah · 2:255 - 2:256; Āli-ʿImrān · 3:18")
        XCTAssertEqual(
            text.rawValue(locale: arabic),
            "\u{E905} · ٢:٢٥٥ - ٢:٢٥٦\(l("list.separator"))\u{E906} · ٣:١٨"
        )
        XCTAssertEqual(text.accessibilityText, "Al-Baqarah, Ayah 255 - 2:256; Āli-ʿImrān, Ayah 18")
    }

    // MARK: Accessibility

    func test_references_useLocalizedAccessibilityTextInEveryStyle() {
        for style in [SuraNameStyle.standard, .decorated, .text] {
            let suraText: MultipartText = "\(sura: sura, emphasizingSura: true, nameStyle: style)"
            let ayahText: MultipartText = "\(ayah: ayah, nameStyle: style)"
            let surasText: MultipartText = "\(suras: Array(Quran.hafsMadani1405.suras[0 ... 1]), nameStyle: style)"

            XCTAssertEqual(suraText.accessibilityText, sura.localizedName(), "\(style)")
            XCTAssertEqual(ayahText.accessibilityText, ayah.localizedName, "\(style)")
            XCTAssertEqual(surasText.accessibilityText, "Al-Fātihah, Al-Baqarah", "\(style)")
        }
    }

    func test_ayahRange_usesSemanticAccessibilityText() {
        let end = sura.verses[255]
        let text: MultipartText = "\(ayahRange: ayah ... end)"

        XCTAssertEqual(text.accessibilityText, "\(ayah.localizedName) - \(end.localizedCoordinate())")
    }

    // MARK: Quran text

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

    func test_highlighting_boldInsideSmallerRangeKeepsSmallerSize() throws {
        let value = "Verse note"
        let note = try XCTUnwrap(value.range(of: "note"))
        let attributedString = HighlightingRange.attributedString(
            value,
            ranges: [
                HighlightingRange(note, foregroundColor: .secondary, fontSize: .footnote),
                HighlightingRange(value.startIndex ..< value.endIndex, fontWeight: .heavy),
            ],
            size: .body
        )

        let texts = attributedString.runs.map { String(attributedString[$0.range].characters) }
        XCTAssertEqual(texts, ["Verse ", "note"])
        let runs = Array(attributedString.runs)
        XCTAssertEqual(runs[0].font, Font.body.weight(.heavy))
        XCTAssertEqual(runs[1].font, Font.footnote.weight(.heavy))
        XCTAssertEqual(runs[1].foregroundColor, .secondary)
    }

    private let sura = Quran.hafsMadani1405.suras[1]
    private let ayah = Quran.hafsMadani1405.suras[1].verses[254]
    private let english = Locale(identifier: "en-CA")
    private let arabic = Locale(identifier: "ar-SA")
    private let chinese = Locale(identifier: "zh")

    /// The decorated sura-name glyphs live in the Unicode private-use area.
    private func containsDecoratedGlyph(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0xE000 ... 0xF8FF).contains($0.value) }
    }
}

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

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) 2:255")
    }

    func test_ayahReference_inArabicLocale_usesGlyphAndLocalizedCoordinate() {
        let text: MultipartText = "\(ayah: ayah)"

        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905} ٢:٢٥٥")
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
        XCTAssertEqual(ayahText.rawValue(locale: english), "\(sura.localizedName()) 2:255")
        XCTAssertEqual(ayahText.rawValue(locale: arabic), "\(sura.localizedName(language: .arabic)) ٢:٢٥٥")
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

        XCTAssertEqual(text.rawValue(locale: english), "\(sura.localizedName()) \u{E905} 2:255")
    }

    func test_decoratedAyahReference_inArabicLocale_usesGlyphAndLocalizedCoordinate() {
        let text: MultipartText = "\(ayah: ayah, nameStyle: .decorated)"

        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905} ٢:٢٥٥")
    }

    // MARK: Ranges

    func test_singleAyahRange_usesStartReference() {
        let text = MultipartText.ayahRange(ayah ... ayah, language: .english)

        XCTAssertEqual(text.rawValue(locale: english), "Al-Baqarah 2:255")
    }

    func test_sameSuraAyahRange_writesTheEndAsItsAyahNumber() {
        let text = MultipartText.ayahRange(ayah ... sura.verses[259], language: .english)

        XCTAssertEqual(text.rawValue(locale: english), "Al-Baqarah 2:255–260")
        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E905} \u{2066}٢:٢٥٥–٢٦٠\u{2069}")
    }

    func test_crossSuraAyahRange_joinsBothReferences() {
        let range = fatihahEnd ... baqarahStart

        XCTAssertEqual(
            MultipartText.ayahRange(range, language: .english).rawValue(locale: english),
            "Al-Fātihah 1:7\u{00A0}– Al-Baqarah 2:1"
        )
        XCTAssertEqual(
            MultipartText.ayahRange(range, language: .arabic).rawValue(locale: arabic),
            "\u{E904} ١:٧\u{00A0}– \u{E905} ٢:١"
        )
    }

    func test_crossSuraAyahRange_wrapsOnlyAfterTheDash() {
        let text: MultipartText = "Playing \(ayahRange: fatihahEnd ... baqarahStart)"

        let lines = text.parts.flatMap(\.wrappingParts).map { $0.rawValue(locale: english) }

        XCTAssertEqual(lines, ["Playing ", "", "Al-Fātihah 1:7\u{00A0}– ", "Al-Baqarah 2:1", ""])
    }

    func test_wholeSuraAyahRange_namesOnlyTheSura() {
        let fatihah = Quran.hafsMadani1405.suras[0]
        let text = MultipartText.ayahRange(fatihah.firstVerse ... fatihah.lastVerse, language: .english)

        XCTAssertEqual(text.rawValue(locale: english), "Al-Fātihah")
        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E904}")
    }

    @MainActor
    func test_ayahRange_attributedStringMatchesRawValue() {
        let sameSura = MultipartText.ayahRange(ayah ... sura.verses[259], language: .english)
        let crossSura = MultipartText.ayahRange(fatihahEnd ... baqarahStart, language: .english)

        XCTAssertEqual(sameSura.attributedString(ofSize: .body, locale: english).string, sameSura.rawValue(locale: english))
        XCTAssertEqual(crossSura.attributedString(ofSize: .body, locale: english).string, crossSura.rawValue(locale: english))
    }

    @MainActor
    func test_arabicAyahRange_attributedStringStartsRightToLeft() {
        let text = MultipartText.ayahRange(ayah ... sura.verses[259], language: .arabic)

        XCTAssertEqual(text.attributedString(ofSize: .body, locale: arabic).string, "\u{200F}\u{E905} \u{2066}٢:٢٥٥–٢٦٠\u{2069}")
    }

    func test_ayahRanges_separatesRangesWithTheListSeparator() {
        let imranEnd = Quran.hafsMadani1405.suras[2].lastVerse
        let nisaStart = Quran.hafsMadani1405.suras[3].firstVerse
        let text: MultipartText = "\(ayahRanges: [ayah ... sura.verses[255], imranEnd ... nisaStart])"

        XCTAssertEqual(text.rawValue(locale: english), "Al-Baqarah 2:255–256; Āli-ʿImrān 3:200\u{00A0}– An-Nisāʾ 4:1")
        XCTAssertEqual(
            text.rawValue(locale: arabic),
            "\u{E905} \u{2066}٢:٢٥٥–٢٥٦\u{2069}\(l("list.separator"))\u{E906} ٣:٢٠٠\u{00A0}– \u{E907} ٤:١"
        )
        XCTAssertEqual(
            text.accessibilityText,
            "Al-Baqarah, Ayahs 255 to 256; Āli-ʿImrān, Ayah 200 to An-Nisāʾ, Ayah 1"
        )
    }

    // MARK: Page references

    func test_pageReference_inNonArabicLocale_usesFirstSuraNameAndPage() {
        let text: MultipartText = "\(page: page)"

        XCTAssertEqual(text.rawValue(locale: english), "At-Tawbah, Page 200")
    }

    func test_pageReference_inArabicLocale_usesFirstSuraGlyphAndAppLanguagePage() {
        let text: MultipartText = "\(page: page)"

        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E90E}, Page 200")
    }

    func test_textPageReference_inArabicLocale_usesPlainArabicNameWithoutGlyph() {
        let text: MultipartText = "\(page: page, nameStyle: .text)"
        let rawValue = text.rawValue(locale: arabic)

        XCTAssertEqual(rawValue, "\(page.startSura.localizedName(language: .arabic)), Page 200")
        XCTAssertFalse(containsDecoratedGlyph(rawValue))
    }

    // MARK: Accessibility

    func test_references_useLocalizedAccessibilityTextInEveryStyle() {
        for style in [SuraNameStyle.standard, .decorated, .text] {
            let suraText: MultipartText = "\(sura: sura, emphasizingSura: true, nameStyle: style)"
            let ayahText: MultipartText = "\(ayah: ayah, nameStyle: style)"
            let surasText: MultipartText = "\(suras: Array(Quran.hafsMadani1405.suras[0 ... 1]), nameStyle: style)"
            let pageText: MultipartText = "\(page: page, nameStyle: style)"

            XCTAssertEqual(suraText.accessibilityText, sura.localizedName(), "\(style)")
            XCTAssertEqual(ayahText.accessibilityText, ayah.localizedName, "\(style)")
            XCTAssertEqual(surasText.accessibilityText, "Al-Fātihah, Al-Baqarah", "\(style)")
            XCTAssertEqual(pageText.accessibilityText, "At-Tawbah, Page 200", "\(style)")
        }
    }

    func test_ayahRange_readsAyahNumbersInsteadOfCoordinates() {
        let sameSura = MultipartText.ayahRange(ayah ... sura.verses[259], language: .english)
        let crossSura = MultipartText.ayahRange(fatihahEnd ... baqarahStart, language: .english)

        XCTAssertEqual(sameSura.accessibilityText, "Al-Baqarah, Ayahs 255 to 260")
        XCTAssertEqual(crossSura.accessibilityText, "Al-Fātihah, Ayah 7 to Al-Baqarah, Ayah 1")
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
    private let page = Quran.hafsMadani1405.pages[199]
    private let fatihahEnd = Quran.hafsMadani1405.suras[0].lastVerse
    private let baqarahStart = Quran.hafsMadani1405.suras[1].firstVerse
    private let english = Locale(identifier: "en-CA")
    private let arabic = Locale(identifier: "ar-SA")

    /// The decorated sura-name glyphs live in the Unicode private-use area.
    private func containsDecoratedGlyph(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0xE000 ... 0xF8FF).contains($0.value) }
    }
}

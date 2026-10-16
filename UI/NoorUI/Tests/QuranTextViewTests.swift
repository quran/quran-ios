//
//  QuranTextViewTests.swift
//
//
//  Created by Mohamed Afifi on 2026-07-26.
//

import Localization
import NoorFont
import QuranKit
import QuranText
import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

final class QuranTextViewTests: XCTestCase {
    #if QURAN_SYNC
    func test_ayahNumber_withoutIndicators_keepsTheSameTouchTargetHeight() async {
        let sizes = await MainActor.run {
            let verse = Quran.hafsMadani1405.firstVerse
            let plain = QuranVerseNumber(verse: verse, indicators: [], onTapped: { _ in })
            let indicated = QuranVerseNumber(verse: verse, indicators: [.note], onTapped: { _ in })
            return (fittingSize(plain), fittingSize(indicated))
        }
        XCTAssertEqual(sizes.0.height, sizes.1.height, accuracy: 1)
    }
    #endif

    func test_readingFont_usesIndoPakFontOnlyForIndoPakReading() {
        XCTAssertEqual(Reading.indoPak.quranFont, .indoPak)
        XCTAssertEqual(Reading.hafs_1405.quranFont, .uthmanicHafs)
    }

    func test_indopakTranslation_usesUthmanicHafsOnlyForAyahMarker() throws {
        let verse = Quran.hafsIndoPak.firstVerse
        let marker = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
        let text = QuranText("IndoPak verse \(marker)")
        let view = QuranArabicText(verse: verse, text: text, quranFont: .indoPak, fontSize: .medium)

        let override = try XCTUnwrap(view.ayahMarkerFontOverrides.first)
        XCTAssertEqual(view.ayahMarkerFontOverrides.count, 1)
        XCTAssertEqual(String(text.text[override.range]), marker)
        XCTAssertEqual(override.quranFont, .uthmanicHafs)
    }

    func test_view_fontCannotBeOverriddenByInheritedFont() async {
        let sizes = await MainActor.run {
            let expected = fittingSize(QuranTextView("Quran text"))
            let inherited = fittingSize(
                QuranTextView("Quran text")
                    .font(.system(size: 100))
            )
            return (expected, inherited)
        }

        XCTAssertEqual(sizes.1.width, sizes.0.width, accuracy: 1)
        XCTAssertEqual(sizes.1.height, sizes.0.height, accuracy: 1)
    }

    func test_indopakJuzRow_matchesMadaniVerticalSpacing() async throws {
        for language in Self.typesettingLanguages {
            let heights = try await MainActor.run {
                registerFontsIfNeeded()
                let value = QuranText("بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ ١")
                let uthmanicText: MultipartText = "\(quran: value, font: .uthmanicHafs, lineLimit: 1)"
                let indoPakText: MultipartText = "\(quran: value, font: .indoPak, lineLimit: 1)"
                let madaniReference: MultipartText = "\(ayah: Quran.hafsMadani1405.firstVerse, nameStyle: .decorated)"
                let indoPakReference: MultipartText = "\(ayah: Quran.hafsIndoPak.firstVerse, nameStyle: .decorated)"
                let madaniItem = NoorListItem(
                    subheading: "Hizb 1",
                    title: madaniReference,
                    rightSubtitle: uthmanicText,
                    accessory: .text("1")
                )
                let indoPakItem = NoorListItem(
                    subheading: "Hizb 1",
                    title: indoPakReference,
                    rightSubtitle: indoPakText,
                    accessory: .text("2")
                )
                return try (
                    constrainedSize(typesetting(madaniItem, language: language)).height,
                    constrainedSize(typesetting(indoPakItem, language: language)).height
                )
            }

            XCTAssertEqual(heights.1, heights.0, accuracy: 1, "\(language)")
        }
    }

    func test_indopakSuraRowWithSubtitle_matchesMadaniVerticalSpacing() async throws {
        for language in Self.typesettingLanguages {
            let heights = try await MainActor.run {
                registerFontsIfNeeded()
                let subtitle = NoorListItem.Subtitle(text: "Note", location: .bottom)
                let madaniItem = NoorListItem(title: "\(sura: Quran.hafsMadani1405.firstSura, nameStyle: .decorated)", subtitle: subtitle)
                let indoPakItem = NoorListItem(title: "\(sura: Quran.hafsIndoPak.firstSura, nameStyle: .decorated)", subtitle: subtitle)
                return try (
                    constrainedSize(typesetting(madaniItem, language: language)).height,
                    constrainedSize(typesetting(indoPakItem, language: language)).height
                )
            }

            XCTAssertEqual(heights.1, heights.0, accuracy: 1, "\(language)")
        }
    }

    func test_indopakSuraReference_matchesMadaniHeight() async throws {
        let references: [(madani: MultipartText, indoPak: MultipartText)] = [
            ("\(ayah: Quran.hafsMadani1405.firstVerse, nameStyle: .decorated)", "\(ayah: Quran.hafsIndoPak.firstVerse, nameStyle: .decorated)"),
            ("\(sura: Quran.hafsMadani1405.firstSura, nameStyle: .decorated)", "\(sura: Quran.hafsIndoPak.firstSura, nameStyle: .decorated)"),
        ]
        for language in Self.typesettingLanguages {
            for locale in [Locale(identifier: "en"), Locale(identifier: "ar")] {
                for size in [MultipartText.FontSize.body, .caption] {
                    for reference in references {
                        let heights = try await MainActor.run {
                            registerFontsIfNeeded()
                            return try (
                                fittingSize(typesetting(reference.madani.view(ofSize: size), language: language, locale: locale)).height,
                                fittingSize(typesetting(reference.indoPak.view(ofSize: size), language: language, locale: locale)).height
                            )
                        }

                        XCTAssertEqual(
                            heights.1,
                            heights.0,
                            accuracy: 0.5,
                            "\(reference.indoPak.rawValue) \(language) \(locale.identifier) \(size)"
                        )
                    }
                }
            }
        }
    }

    // MARK: Private

    /// Arabic typesetting gives the system font a taller line box than English does, whatever the host's languages are.
    private static let typesettingLanguages = ["en", "ar"]

    @MainActor
    private func registerFontsIfNeeded() {
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
    }

    @MainActor
    private func typesetting(_ content: some View, language: String, locale: Locale = Locale(identifier: "en")) throws -> some View {
        guard #available(iOS 17, *) else {
            throw XCTSkip("Typesetting languages need iOS 17.")
        }
        return content
            .typesettingLanguage(Locale.Language(identifier: language))
            .environment(\.locale, locale)
    }

    @MainActor
    private func fittingSize(_ content: some View) -> CGSize {
        let controller = UIHostingController(rootView: content.fixedSize())
        return controller.sizeThatFits(
            in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
    }

    @MainActor
    private func constrainedSize(_ content: some View) -> CGSize {
        let controller = UIHostingController(rootView: content)
        return controller.sizeThatFits(in: CGSize(width: 300, height: 1000))
    }
}

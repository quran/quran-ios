//
//  QuranTextViewTests.swift
//
//
//  Created by Mohamed Afifi on 2026-07-26.
//

import Localization
import QuranKit
import QuranText
import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

final class QuranTextViewTests: XCTestCase {
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

    @MainActor
    private func fittingSize(_ content: some View) -> CGSize {
        let controller = UIHostingController(rootView: content.fixedSize())
        return controller.sizeThatFits(
            in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
    }
}

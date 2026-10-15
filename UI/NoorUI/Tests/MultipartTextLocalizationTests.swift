//
//  MultipartTextLocalizationTests.swift
//
//
//  Created by Mohamed Afifi on 2026-07-19.
//

import Localization
import QuranKit
import QuranLocalization
import XCTest
@testable import NoorUI

final class MultipartTextLocalizationTests: XCTestCase {
    func test_localizedFormat_insertsMultipartTextArguments() {
        let start: MultipartText = "\(ayah: Quran.hafsMadani1405.suras[1].verses[254])"
        let end: MultipartText = "\(ayah: Quran.hafsMadani1405.suras[1].verses[255])"

        let result = MultipartText.localizedFormat(
            "audio.playing.message",
            language: .english,
            start,
            end
        )

        XCTAssertEqual(
            result.rawValue(locale: Locale(identifier: "en")),
            "Playing audio from Al-Baqarah · 2:255 to Al-Baqarah · 2:256"
        )
    }

    func test_format_supportsReorderedAndRepeatedArguments() {
        let first: MultipartText = "first"
        let second: MultipartText = "second"

        let result = MultipartText.format(
            "%2$@ / %1$@ / %2$@",
            arguments: [first, second]
        )

        XCTAssertEqual(result.rawValue(locale: Locale(identifier: "en")), "second / first / second")
    }

    func test_surasInterpolation_separatesEverySuraName() {
        let text: MultipartText = "\(suras: suras)"

        XCTAssertEqual(text.rawValue(locale: english), "Al-Isrāʾ · Al-Kahf")
    }

    func test_surasInterpolation_inArabicLocale_usesDecoratedGlyphs() {
        let text: MultipartText = "\(suras: suras)"

        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E916} · \u{E917}")
    }

    func test_decoratedSurasInterpolation_addsDecoratedGlyphs() {
        let text: MultipartText = "\(suras: suras, nameStyle: .decorated)"

        XCTAssertEqual(text.rawValue(locale: english), "Al-Isrāʾ \u{E916} · Al-Kahf \u{E917}")
        XCTAssertEqual(text.rawValue(locale: arabic), "\u{E916} · \u{E917}")
    }

    func test_textSurasInterpolation_inArabicLocale_usesPlainArabicNames() {
        let text: MultipartText = "\(suras: suras, nameStyle: .text)"

        XCTAssertEqual(text.rawValue(locale: arabic), "الإِسۡرَاءِ · الكَهۡفِ")
    }

    private let suras = Quran.hafsMadani1405.pages[292].suras
    private let english = Locale(identifier: "en")
    private let arabic = Locale(identifier: "ar")
}

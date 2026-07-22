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
            "Playing audio from Al-Baqarah \u{E905} · 2:255 to Al-Baqarah \u{E905} · 2:256"
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
}

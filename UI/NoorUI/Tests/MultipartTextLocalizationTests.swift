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
        let sura = Quran.hafsMadani1405.suras[1]
        let start: MultipartText = "Al-Baqarah 2:255 \(sura: sura)"
        let end: MultipartText = "Al-Baqarah 2:256"

        let result = MultipartText.localizedFormat(
            "audio.playing.message",
            language: .english,
            start,
            end
        )

        XCTAssertEqual(
            result.rawValue,
            "Playing audio from Al-Baqarah 2:255 \(sura.localizedName()) \u{E905} to Al-Baqarah 2:256"
        )
    }

    func test_format_supportsReorderedAndRepeatedArguments() {
        let first: MultipartText = "first"
        let second: MultipartText = "second"

        let result = MultipartText.format(
            "%2$@ / %1$@ / %2$@",
            arguments: [first, second]
        )

        XCTAssertEqual(result.rawValue, "second / first / second")
    }
}

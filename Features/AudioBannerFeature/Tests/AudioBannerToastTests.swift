//
//  AudioBannerToastTests.swift
//

import QuranKit
import XCTest
@testable import AudioBannerFeature
@testable import NoorUI

@MainActor
final class AudioBannerToastTests: XCTestCase {
    func test_playingToast_namesOnlyTheSuraWhenItPlaysWhole() {
        let fatihah = Quran.hafsMadani1405.suras[0]

        let message = AudioBannerViewModel.audioMessage(
            "audio.playing.toast",
            audioRange: (start: fatihah.firstVerse, end: fatihah.lastVerse)
        )

        XCTAssertEqual(message.rawValue(locale: english), "Playing Al-Fātihah")
    }

    func test_downloadingToast_writesTheRangeCompactly() {
        let baqarah = Quran.hafsMadani1405.suras[1]

        let message = AudioBannerViewModel.audioMessage(
            "audio.downloading.toast",
            audioRange: (start: baqarah.verses[0], end: baqarah.verses[9])
        )

        XCTAssertEqual(message.rawValue(locale: english), "Downloading audio for Al-Baqarah · 2:1–10")
        XCTAssertEqual(message.accessibilityText, "Downloading audio for Al-Baqarah, Ayahs 1 to 10")
    }

    private let english = Locale(identifier: "en-CA")
}

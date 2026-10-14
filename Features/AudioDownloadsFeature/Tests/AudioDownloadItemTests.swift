//
//  AudioDownloadItemTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import QuranAudio
import XCTest
@testable import AudioDownloadsFeature

final class AudioDownloadItemTests: XCTestCase {
    func test_formattedString_separatesSizeAndSurasWithMetadataSeparator() {
        let size: AudioDownloadedSize? = AudioDownloadedSize(
            downloadedSizeInBytes: 1_000_000,
            downloadedSuraCount: 5,
            surasCount: 114
        )

        XCTAssertEqual(size.formattedString(), "1MB · 5 surahs downloaded")
    }

    func test_formattedString_showsOnlySurasWhenNothingIsDownloaded() {
        let size: AudioDownloadedSize? = AudioDownloadedSize(
            downloadedSizeInBytes: 0,
            downloadedSuraCount: 0,
            surasCount: 114
        )

        XCTAssertEqual(size.formattedString(), "0 surahs downloaded")
    }
}

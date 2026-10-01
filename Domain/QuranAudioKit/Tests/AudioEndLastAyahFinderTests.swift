//
//  AudioEndLastAyahFinderTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import QuranAudio
import QuranKit
import XCTest
@testable import QuranAudioKit

final class AudioEndLastAyahFinderTests: XCTestCase {
    // MARK: Internal

    func test_findLastAyah_floorsBoundaryToEndOfStartPage() {
        // Al-Qadr ends mid-page.
        let alQadr = quran.suras[96]
        let pageEnd = PageBasedLastAyahFinder().findLastAyah(startAyah: alQadr.firstVerse)
        XCTAssertLessThan(alQadr.lastVerse, pageEnd)

        let lastAyah = AudioEndLastAyahFinder(audioEnd: .sura).findLastAyah(startAyah: alQadr.firstVerse)

        XCTAssertEqual(lastAyah, pageEnd)
    }

    func test_findLastAyah_keepsBoundaryPastStartPage() {
        let alBaqarah = quran.suras[1]

        let lastAyah = AudioEndLastAyahFinder(audioEnd: .sura).findLastAyah(startAyah: alBaqarah.firstVerse)

        XCTAssertEqual(lastAyah, alBaqarah.lastVerse)
    }

    func test_boundaryLastAyahFinder_doesNotFloorToPage() {
        let alQadr = quran.suras[96]

        let lastAyah = AudioEnd.sura.boundaryLastAyahFinder.findLastAyah(startAyah: alQadr.firstVerse)

        XCTAssertEqual(lastAyah, alQadr.lastVerse)
    }

    func test_preferencesLastAyahFinder_floorsTheSavedAudioEnd() {
        let originalAudioEnd = AudioPreferences.shared.audioEnd
        defer { AudioPreferences.shared.audioEnd = originalAudioEnd }
        AudioPreferences.shared.audioEnd = .sura
        let alQadr = quran.suras[96]

        let lastAyah = PreferencesLastAyahFinder.shared.findLastAyah(startAyah: alQadr.firstVerse)

        XCTAssertEqual(lastAyah, PageBasedLastAyahFinder().findLastAyah(startAyah: alQadr.firstVerse))
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
}

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

    func test_findLastAyah_endsQuarterExactly_withoutThePageFloor() {
        // Quarter 9 ends at Al-Baqarah 157, mid-page 24 (2:154–163).
        let start = ayah(2, 154)
        let pageEnd = PageBasedLastAyahFinder().findLastAyah(startAyah: start)
        XCTAssertLessThan(ayah(2, 157), pageEnd)

        let lastAyah = AudioEndLastAyahFinder(audioEnd: .quarter).findLastAyah(startAyah: start)

        XCTAssertEqual(lastAyah, ayah(2, 157))
    }

    func test_findLastAyah_endsHizbExactly_withoutThePageFloor() {
        // Hizb 1 ends at Al-Baqarah 74, mid-page 11 (2:70–76).
        let start = ayah(2, 70)
        let pageEnd = PageBasedLastAyahFinder().findLastAyah(startAyah: start)
        XCTAssertLessThan(ayah(2, 74), pageEnd)

        let lastAyah = AudioEndLastAyahFinder(audioEnd: .hizb).findLastAyah(startAyah: start)

        XCTAssertEqual(lastAyah, ayah(2, 74))
    }

    func test_findLastAyah_floorsPageSurahJuzAndQuran() {
        // Al-Qadr ends mid-page; every floored boundary plays at least to that page's end.
        let start = quran.suras[96].firstVerse
        let pageEnd = PageBasedLastAyahFinder().findLastAyah(startAyah: start)

        for audioEnd in [AudioEnd.page, .sura, .juz, .quran] {
            let lastAyah = AudioEndLastAyahFinder(audioEnd: audioEnd).findLastAyah(startAyah: start)

            XCTAssertGreaterThanOrEqual(lastAyah, pageEnd, "\(audioEnd)")
        }
    }

    func test_preferencesLastAyahFinder_endsTheSavedQuarterAndHizbExactly() {
        let originalAudioEnd = AudioPreferences.shared.audioEnd
        defer { AudioPreferences.shared.audioEnd = originalAudioEnd }

        AudioPreferences.shared.audioEnd = .quarter
        XCTAssertEqual(PreferencesLastAyahFinder.shared.findLastAyah(startAyah: ayah(2, 154)), ayah(2, 157))

        AudioPreferences.shared.audioEnd = .hizb
        XCTAssertEqual(PreferencesLastAyahFinder.shared.findLastAyah(startAyah: ayah(2, 70)), ayah(2, 74))
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405

    private func ayah(_ sura: Int, _ ayah: Int) -> AyahNumber {
        AyahNumber(quran: quran, sura: sura, ayah: ayah)!
    }
}

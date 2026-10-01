//
//  HizbBasedLastAyahFinderTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import QuranKit
import XCTest

final class HizbBasedLastAyahFinderTests: XCTestCase {
    // MARK: Internal

    func test_findLastAyah_fromHizbFirstVerse_endsBeforeNextHizb() {
        // Hizb 6 starts at Al-Imran 15; hizb 7 starts at 93.
        let lastAyah = finder.findLastAyah(startAyah: ayah(3, 15))

        XCTAssertEqual(lastAyah, ayah(3, 92))
    }

    func test_findLastAyah_fromMidHizb_endsWithThatHizb() {
        // Al-Imran 52 starts hizb 6's third quarter.
        let lastAyah = finder.findLastAyah(startAyah: ayah(3, 52))

        XCTAssertEqual(lastAyah, ayah(3, 92))
    }

    func test_findLastAyah_acrossSuras_endsWithTheHizb() {
        // Hizb 5 starts at Al-Baqarah 253 and ends at Al-Imran 14.
        let lastAyah = finder.findLastAyah(startAyah: ayah(2, 255))

        XCTAssertEqual(lastAyah, ayah(3, 14))
    }

    func test_findLastAyah_inFinalHizb_endsWithTheQuran() {
        // The final hizb starts at Al-A'la 1.
        XCTAssertEqual(finder.findLastAyah(startAyah: ayah(87, 1)), quran.lastVerse)
        XCTAssertEqual(finder.findLastAyah(startAyah: ayah(90, 1)), quran.lastVerse)
    }

    func test_findLastAyah_beforeFinalHizb_endsBeforeIt() {
        XCTAssertEqual(finder.findLastAyah(startAyah: ayah(86, 17)), ayah(86, 17))
    }

    func test_findLastAyah_endsEveryHizbAtItsLastVerse() {
        for hizb in quran.hizbs {
            XCTAssertEqual(finder.findLastAyah(startAyah: hizb.firstVerse), hizb.lastVerse, "\(hizb)")
        }
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
    private let finder = HizbBasedLastAyahFinder()

    private func ayah(_ sura: Int, _ ayah: Int) -> AyahNumber {
        AyahNumber(quran: quran, sura: sura, ayah: ayah)!
    }
}

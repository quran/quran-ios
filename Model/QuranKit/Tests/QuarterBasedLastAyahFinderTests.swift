//
//  QuarterBasedLastAyahFinderTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import QuranKit
import XCTest

final class QuarterBasedLastAyahFinderTests: XCTestCase {
    // MARK: Internal

    func test_findLastAyah_fromQuarterFirstVerse_endsBeforeNextQuarter() {
        // Quarter 9 starts at Al-Baqarah 142; quarter 10 starts at 158.
        let lastAyah = finder.findLastAyah(startAyah: ayah(2, 142))

        XCTAssertEqual(lastAyah, ayah(2, 157))
    }

    func test_findLastAyah_fromMidQuarter_endsWithThatQuarter() {
        let lastAyah = finder.findLastAyah(startAyah: ayah(2, 150))

        XCTAssertEqual(lastAyah, ayah(2, 157))
    }

    func test_findLastAyah_fromQuarterLastVerse_staysInThatQuarter() {
        let lastAyah = finder.findLastAyah(startAyah: ayah(2, 157))

        XCTAssertEqual(lastAyah, ayah(2, 157))
    }

    func test_findLastAyah_fromFirstVerse_endsTheFirstQuarter() {
        let lastAyah = finder.findLastAyah(startAyah: quran.firstVerse)

        XCTAssertEqual(lastAyah, ayah(2, 25))
    }

    func test_findLastAyah_inLastQuarter_endsWithTheQuran() {
        // The last quarter starts at Al-Adiyat 9.
        let lastAyah = finder.findLastAyah(startAyah: ayah(112, 1))

        XCTAssertEqual(lastAyah, quran.lastVerse)
        XCTAssertEqual(finder.findLastAyah(startAyah: ayah(100, 9)), quran.lastVerse)
    }

    func test_findLastAyah_endsEveryQuarterAtItsLastVerse() {
        for quarter in quran.quarters {
            XCTAssertEqual(finder.findLastAyah(startAyah: quarter.firstVerse), quarter.lastVerse, "\(quarter)")
        }
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
    private let finder = QuarterBasedLastAyahFinder()

    private func ayah(_ sura: Int, _ ayah: Int) -> AyahNumber {
        AyahNumber(quran: quran, sura: sura, ayah: ayah)!
    }
}

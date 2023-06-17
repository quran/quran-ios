//
//  SuraTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-11.
//

import XCTest
@testable import QuranKit

final class SuraTests: XCTestCase {
    private let quran = Quran.hafsMadani1405

    func testSuras() throws {
        let suras = quran.suras
        XCTAssertEqual(suras.count, 114)
        XCTAssertEqual(suras.first!.suraNumber, 1)
        XCTAssertEqual(suras.last!.suraNumber, 114)
        XCTAssertEqual(suras[21].suraNumber, 22)

        XCTAssertEqual(suras[0].description, "<Sura value=1>")
        XCTAssertEqual(suras[29].description, "<Sura value=30>")

        XCTAssertEqual(suras[1], suras[0].next)
        XCTAssertEqual(suras[29], suras[28].next)
        XCTAssertEqual(suras[29], suras[27].next?.next)
        XCTAssertNil(suras.last!.next)

        XCTAssertEqual(suras[0], suras[1].previous)
        XCTAssertEqual(suras[28], suras[29].previous)
        XCTAssertEqual(suras[27], suras[29].previous?.previous)
        XCTAssertNil(suras[0].previous)

        XCTAssertTrue(suras[3] == suras[3])
        XCTAssertTrue(suras[3] < suras[4])
        XCTAssertTrue(suras[3] > suras[2])

        XCTAssertEqual(suras[0].startsWithBesmAllah, false)
        XCTAssertEqual(suras[8].startsWithBesmAllah, false)
        XCTAssertEqual(suras[17].startsWithBesmAllah, true)

        XCTAssertEqual(suras[29].isMakki, true)
        XCTAssertEqual(suras[3].isMakki, false)
        XCTAssertEqual(suras[17].isMakki, true)

        XCTAssertEqual(suras[112].page.pageNumber, 604)
        XCTAssertEqual(suras[113].page.pageNumber, 604)
        XCTAssertEqual(suras[17].page.pageNumber, 293)

        XCTAssertEqual(suras[29].numberOfVerses, 60)
        XCTAssertEqual(suras[3].numberOfVerses, 176)
        XCTAssertEqual(suras[17].numberOfVerses, 110)

        XCTAssertEqual(Set(suras[29].verses.map(\.sura)), [suras[29]])
        XCTAssertEqual(suras[29].verses.map(\.ayah), Array(1 ... 60))

        XCTAssertEqual(Set(suras[3].verses.map(\.sura)), [suras[3]])
        XCTAssertEqual(suras[3].verses.map(\.ayah), Array(1 ... 176))

        XCTAssertEqual(Set(suras[17].verses.map(\.sura)), [suras[17]])
        XCTAssertEqual(suras[17].verses.map(\.ayah), Array(1 ... 110))

        XCTAssertEqual(suras[4].array(to: suras[4]), [suras[4]])
        XCTAssertEqual(suras[4].array(to: suras[10]), Array(suras[4 ... 10]))
        XCTAssertEqual(suras[0].array(to: suras[113]), suras)

        XCTAssertEqual(suras.first!.firstVerse.sura.suraNumber, 1)
        XCTAssertEqual(suras.first!.firstVerse.ayah, 1)
        XCTAssertEqual(suras.first!.lastVerse.sura.suraNumber, 1)
        XCTAssertEqual(suras.first!.lastVerse.ayah, 7)

        XCTAssertEqual(suras.last!.firstVerse.sura.suraNumber, 114)
        XCTAssertEqual(suras.last!.firstVerse.ayah, 1)
        XCTAssertEqual(suras.last!.lastVerse.sura.suraNumber, 114)
        XCTAssertEqual(suras.last!.lastVerse.ayah, 6)

        XCTAssertEqual(suras[24].firstVerse.sura.suraNumber, 25)
        XCTAssertEqual(suras[24].firstVerse.ayah, 1)
        XCTAssertEqual(suras[24].lastVerse.sura.suraNumber, 25)
        XCTAssertEqual(suras[24].lastVerse.ayah, 77)
    }

    func testSurasPagesTime() {
        measure {
            let quran = Quran(raw: Madani1405QuranReadingInfoRawData())
            let suras = quran.suras
            _ = Dictionary(grouping: suras, by: { $0.page.startJuz })
        }
    }

    func testSurasPagesCachedTime() {
        let quran = Quran(raw: Madani1405QuranReadingInfoRawData())
        let suras = quran.suras
        _ = Dictionary(grouping: suras, by: { $0.page.startJuz })

        measure {
            let suras = quran.suras
            _ = Dictionary(grouping: suras, by: { $0.page.startJuz })
        }
    }
}

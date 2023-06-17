//
//  JuzTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-11.
//

import XCTest
@testable import QuranKit

final class JuzTests: XCTestCase {
    private let quran = Quran.hafsMadani1405

    func testJuzs() throws {
        let juzs = quran.juzs
        XCTAssertEqual(juzs.count, 30)
        XCTAssertEqual(juzs.first!.juzNumber, 1)
        XCTAssertEqual(juzs.last!.juzNumber, 30)
        XCTAssertEqual(juzs[21].juzNumber, 22)

        XCTAssertEqual(juzs[0].description, "<Juz value=1>")
        XCTAssertEqual(juzs[29].description, "<Juz value=30>")

        XCTAssertEqual(juzs[1], juzs[0].next)
        XCTAssertEqual(juzs[29], juzs[28].next)
        XCTAssertEqual(juzs[29], juzs[27].next?.next)
        XCTAssertNil(juzs.last!.next)

        XCTAssertEqual(juzs[0], juzs[1].previous)
        XCTAssertEqual(juzs[28], juzs[29].previous)
        XCTAssertEqual(juzs[27], juzs[29].previous?.previous)
        XCTAssertNil(juzs[0].previous)

        XCTAssertTrue(juzs[3] == juzs[3])
        XCTAssertTrue(juzs[3] < juzs[4])
        XCTAssertTrue(juzs[3] > juzs[2])

        XCTAssertEqual(juzs[29].page.pageNumber, 582)
        XCTAssertEqual(juzs[25].page.pageNumber, 502)
        XCTAssertEqual(juzs[3].page.pageNumber, 62)
        XCTAssertEqual(juzs[0].page.pageNumber, 1)

        XCTAssertEqual(juzs[29].hizb.hizbNumber, 59)
        XCTAssertEqual(juzs[3].hizb.hizbNumber, 7)
        XCTAssertEqual(juzs[15].hizb.hizbNumber, 31)

        XCTAssertEqual(juzs[0].quarter.quarterNumber, 1)
        XCTAssertEqual(juzs[1].quarter.quarterNumber, 9)
        XCTAssertEqual(juzs[29].quarter.quarterNumber, 233)
        XCTAssertEqual(juzs[3].quarter.quarterNumber, 25)
        XCTAssertEqual(juzs[17].quarter.quarterNumber, 137)

        XCTAssertEqual(juzs.first!.firstVerse.sura.suraNumber, 1)
        XCTAssertEqual(juzs.first!.firstVerse.ayah, 1)
        XCTAssertEqual(juzs.first!.lastVerse.sura.suraNumber, 2)
        XCTAssertEqual(juzs.first!.lastVerse.ayah, 141)

        XCTAssertEqual(juzs.last!.firstVerse.sura.suraNumber, 78)
        XCTAssertEqual(juzs.last!.firstVerse.ayah, 1)
        XCTAssertEqual(juzs.last!.lastVerse.sura.suraNumber, 114)
        XCTAssertEqual(juzs.last!.lastVerse.ayah, 6)

        XCTAssertEqual(juzs[10].firstVerse.sura.suraNumber, 9)
        XCTAssertEqual(juzs[10].firstVerse.ayah, 93)
        XCTAssertEqual(juzs[10].lastVerse.sura.suraNumber, 11)
        XCTAssertEqual(juzs[10].lastVerse.ayah, 5)

        XCTAssertEqual(juzs[24].firstVerse.sura.suraNumber, 41)
        XCTAssertEqual(juzs[24].firstVerse.ayah, 47)
        XCTAssertEqual(juzs[24].lastVerse.sura.suraNumber, 45)
        XCTAssertEqual(juzs[24].lastVerse.ayah, 37)
    }
}

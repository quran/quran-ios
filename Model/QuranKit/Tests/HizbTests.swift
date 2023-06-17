//
//  HizbTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-11.
//

import XCTest
@testable import QuranKit

final class HizbTests: XCTestCase {
    private let quran = Quran.hafsMadani1405

    func testHizbs() throws {
        let hizbs = quran.hizbs
        XCTAssertEqual(hizbs.count, 60)
        XCTAssertEqual(hizbs.first!.hizbNumber, 1)
        XCTAssertEqual(hizbs.last!.hizbNumber, 60)
        XCTAssertEqual(hizbs[21].hizbNumber, 22)

        XCTAssertEqual(hizbs[0].description, "<Hizb value=1>")
        XCTAssertEqual(hizbs[29].description, "<Hizb value=30>")

        XCTAssertEqual(hizbs[1], hizbs[0].next)
        XCTAssertEqual(hizbs[29], hizbs[28].next)
        XCTAssertEqual(hizbs[29], hizbs[27].next?.next)
        XCTAssertNil(hizbs.last!.next)

        XCTAssertEqual(hizbs[0], hizbs[1].previous)
        XCTAssertEqual(hizbs[28], hizbs[29].previous)
        XCTAssertEqual(hizbs[27], hizbs[29].previous?.previous)
        XCTAssertNil(hizbs[0].previous)

        XCTAssertTrue(hizbs[3] == hizbs[3])
        XCTAssertTrue(hizbs[3] < hizbs[4])
        XCTAssertTrue(hizbs[3] > hizbs[2])

        XCTAssertEqual(hizbs[0].quarter.quarterNumber, 1)
        XCTAssertEqual(hizbs[1].quarter.quarterNumber, 5)
        XCTAssertEqual(hizbs[29].quarter.quarterNumber, 117)
        XCTAssertEqual(hizbs[3].quarter.quarterNumber, 13)
        XCTAssertEqual(hizbs[17].quarter.quarterNumber, 69)

        XCTAssertEqual(hizbs[0].juz.juzNumber, 1)
        XCTAssertEqual(hizbs[1].juz.juzNumber, 1)
        XCTAssertEqual(hizbs[3].juz.juzNumber, 2)
        XCTAssertEqual(hizbs[59].juz.juzNumber, 30)

        XCTAssertEqual(hizbs[4].firstVerse.sura.suraNumber, 2)
        XCTAssertEqual(hizbs[4].firstVerse.ayah, 253)
        XCTAssertEqual(hizbs[5].firstVerse.sura.suraNumber, 3)
        XCTAssertEqual(hizbs[5].firstVerse.ayah, 15)
    }
}

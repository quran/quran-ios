//
//  QuarterTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-11.
//

import XCTest
@testable import QuranKit

final class QuarterTests: XCTestCase {
    private let quran = Quran.hafsMadani1405

    func testQuarters() throws {
        let quarters = quran.quarters
        XCTAssertEqual(quarters.count, 240)
        XCTAssertEqual(quarters.first!.quarterNumber, 1)
        XCTAssertEqual(quarters.last!.quarterNumber, 240)
        XCTAssertEqual(quarters[21].quarterNumber, 22)

        XCTAssertEqual(quarters[0].description, "<Quarter value=1>")
        XCTAssertEqual(quarters[29].description, "<Quarter value=30>")

        XCTAssertEqual(quarters[1], quarters[0].next)
        XCTAssertEqual(quarters[29], quarters[28].next)
        XCTAssertEqual(quarters[29], quarters[27].next?.next)
        XCTAssertNil(quarters.last!.next)

        XCTAssertEqual(quarters[0], quarters[1].previous)
        XCTAssertEqual(quarters[28], quarters[29].previous)
        XCTAssertEqual(quarters[27], quarters[29].previous?.previous)
        XCTAssertNil(quarters[0].previous)

        XCTAssertTrue(quarters[3] == quarters[3])
        XCTAssertTrue(quarters[3] < quarters[4])
        XCTAssertTrue(quarters[3] > quarters[2])

        XCTAssertEqual(quarters[0].firstVerse.sura.suraNumber, 1)
        XCTAssertEqual(quarters[0].firstVerse.ayah, 1)
        XCTAssertEqual(quarters[239].firstVerse.sura.suraNumber, 100)
        XCTAssertEqual(quarters[239].firstVerse.ayah, 9)
        XCTAssertEqual(quarters[8].firstVerse.sura.suraNumber, 2)
        XCTAssertEqual(quarters[8].firstVerse.ayah, 142)

        XCTAssertEqual(quarters[0].page.pageNumber, 1)
        XCTAssertEqual(quarters[7].page.pageNumber, 19)
        XCTAssertEqual(quarters[8].page.pageNumber, 22)
        XCTAssertEqual(quarters[239].page.pageNumber, 599)

        XCTAssertEqual(quarters[0].juz.juzNumber, 1)
        XCTAssertEqual(quarters[7].juz.juzNumber, 1)
        XCTAssertEqual(quarters[8].juz.juzNumber, 2)
        XCTAssertEqual(quarters[239].juz.juzNumber, 30)

        XCTAssertEqual(quarters[0].hizb.hizbNumber, 1)
        XCTAssertEqual(quarters[7].hizb.hizbNumber, 2)
        XCTAssertEqual(quarters[8].hizb.hizbNumber, 3)
        XCTAssertEqual(quarters[239].hizb.hizbNumber, 60)
    }

    func testQuartersJuzTime() {
        measure {
            let quarters = quran.quarters
            _ = Dictionary(grouping: quarters, by: \.juz)
        }
    }
}

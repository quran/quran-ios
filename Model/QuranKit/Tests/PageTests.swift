//
//  PageTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-11.
//

import XCTest
@testable import QuranKit

final class PageTests: XCTestCase {
    private let quran = Quran.hafsMadani1405

    func testPages() throws {
        let pages = quran.pages
        XCTAssertEqual(pages.count, 604)
        XCTAssertEqual(pages.first!.pageNumber, 1)
        XCTAssertEqual(pages.last!.pageNumber, 604)
        XCTAssertEqual(pages[200].pageNumber, 201)

        XCTAssertEqual(pages[0].description, "<Page value=1>")
        XCTAssertEqual(pages[29].description, "<Page value=30>")

        XCTAssertTrue(pages[3] == pages[3])
        XCTAssertTrue(pages[3] < pages[4])
        XCTAssertTrue(pages[3] > pages[2])

        XCTAssertEqual(pages[1], pages[0].next)
        XCTAssertEqual(pages[603], pages[602].next)
        XCTAssertEqual(pages[603], pages[601].next?.next)
        XCTAssertNil(pages.last!.next)

        XCTAssertEqual(pages[0], pages[1].previous)
        XCTAssertEqual(pages[602], pages[603].previous)
        XCTAssertEqual(pages[601], pages[603].previous?.previous)
        XCTAssertNil(pages[0].previous)

        XCTAssertEqual(pages[602].startSura.suraNumber, 109)
        XCTAssertEqual(pages[206].startSura.suraNumber, 9)
        XCTAssertEqual(pages[207].startSura.suraNumber, 10)

        XCTAssertEqual(pages[0].startJuz.juzNumber, 1)
        XCTAssertEqual(pages.last!.startJuz.juzNumber, 30)
        XCTAssertEqual(pages[540].startJuz.juzNumber, 27)
        XCTAssertEqual(pages[541].startJuz.juzNumber, 28)
        XCTAssertEqual(pages[542].startJuz.juzNumber, 28)
        XCTAssertEqual(pages[599].startJuz.juzNumber, 30)
        XCTAssertEqual(pages[1].startJuz.juzNumber, 1)
        XCTAssertEqual(pages[207].startJuz.juzNumber, 11)

        XCTAssertEqual(pages[0].quarter?.quarterNumber, 1)
        XCTAssertNil(pages[1].quarter)
        XCTAssertNil(pages[603].quarter)
        XCTAssertEqual(pages[598].quarter?.quarterNumber, 240)

        XCTAssertEqual(pages.first!.firstVerse.sura.suraNumber, 1)
        XCTAssertEqual(pages.first!.firstVerse.ayah, 1)
        XCTAssertEqual(pages.first!.lastVerse.sura.suraNumber, 1)
        XCTAssertEqual(pages.first!.lastVerse.ayah, 7)

        XCTAssertEqual(pages.last!.firstVerse.sura.suraNumber, 112)
        XCTAssertEqual(pages.last!.firstVerse.ayah, 1)
        XCTAssertEqual(pages.last!.lastVerse.sura.suraNumber, 114)
        XCTAssertEqual(pages.last!.lastVerse.ayah, 6)

        XCTAssertEqual(pages[395].firstVerse.sura.suraNumber, 28)
        XCTAssertEqual(pages[395].firstVerse.ayah, 85)
        XCTAssertEqual(pages[395].lastVerse.sura.suraNumber, 29)
        XCTAssertEqual(pages[395].lastVerse.ayah, 6)
    }
}

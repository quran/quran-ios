//
//  QuranPageMetadataTests.swift
//
//
//  Created by OpenAI on 2026-04-25.
//

import XCTest
@testable import QuranKit

final class QuranPageMetadataTests: XCTestCase {
    private struct SkippedFirstPageReadingInfoRawData: QuranReadingInfoRawData {
        // MARK: Internal

        var arabicBesmAllah: String { base.arabicBesmAllah }
        var numberOfPages: Int { base.numberOfPages + 1 }
        var pagesToSkip: Int { 1 }

        var startPageOfSura: [Int] {
            base.startPageOfSura.map { $0 + pagesToSkip }
        }

        var startSuraOfPage: [Int] {
            [base.startSuraOfPage[0]] + base.startSuraOfPage
        }

        var startAyahOfPage: [Int] {
            [base.startAyahOfPage[0]] + base.startAyahOfPage
        }

        var numberOfAyahsInSura: [Int] { base.numberOfAyahsInSura }
        var isMakkiSura: [Bool] { base.isMakkiSura }
        var quarters: [(sura: Int, ayah: Int)] { base.quarters }

        // MARK: Private

        private let base = Madani1405QuranReadingInfoRawData()
    }

    // MARK: Internal

    func testMadaniReadingsKeepDefaultPageMetadata() {
        for quran in [Quran.hafsMadani1405, Quran.hafsMadani1440] {
            XCTAssertEqual(quran.numberOfPages, 604)
            XCTAssertEqual(quran.pagesToSkip, 0)
            XCTAssertEqual(quran.pages.count, 604)
            XCTAssertEqual(quran.pages.first?.pageNumber, 1)
            XCTAssertEqual(quran.pages.last?.pageNumber, 604)

            XCTAssertNotNil(Page(quran: quran, pageNumber: 1))
            XCTAssertNotNil(Page(quran: quran, pageNumber: 604))
            XCTAssertNil(Page(quran: quran, pageNumber: 605))

            XCTAssertEqual(quran.suras.first?.page.pageNumber, 1)
            XCTAssertEqual(quran.suras.last?.page.pageNumber, 604)
            XCTAssertEqual(quran.firstVerse.page.pageNumber, 1)
            XCTAssertEqual(quran.lastVerse.page.pageNumber, 604)
            XCTAssertEqual(quran.juzs.first?.page.pageNumber, 1)
            XCTAssertEqual(quran.juzs.last?.page.pageNumber, 582)
            XCTAssertEqual(quran.juzs.map(\.page), quran.juzs.map(\.firstVerse.page))
        }
    }

    func testSkippedPageReadingExcludesSkippedPagesFromVisiblePages() {
        let quran = Quran(raw: SkippedFirstPageReadingInfoRawData())

        XCTAssertEqual(quran.numberOfPages, 605)
        XCTAssertEqual(quran.pagesToSkip, 1)
        XCTAssertEqual(quran.pages.count, 604)
        XCTAssertEqual(quran.pages.first?.pageNumber, 2)
        XCTAssertEqual(quran.pages.last?.pageNumber, 605)

        XCTAssertNil(Page(quran: quran, pageNumber: 1))
        XCTAssertNotNil(Page(quran: quran, pageNumber: 2))
        XCTAssertNotNil(Page(quran: quran, pageNumber: 605))
        XCTAssertNil(Page(quran: quran, pageNumber: 606))
    }

    func testSkippedPageReadingKeepsQuranNavigationOnFirstVisiblePage() {
        let quran = Quran(raw: SkippedFirstPageReadingInfoRawData())

        XCTAssertEqual(quran.pages.first?.firstVerse.sura.suraNumber, 1)
        XCTAssertEqual(quran.pages.first?.firstVerse.ayah, 1)
        XCTAssertEqual(quran.firstVerse.page.pageNumber, 2)
        XCTAssertEqual(quran.suras.first?.page.pageNumber, 2)
        XCTAssertEqual(quran.juzs.first?.page.pageNumber, 2)
        XCTAssertEqual(quran.juzs.last?.page.pageNumber, 583)
        XCTAssertEqual(quran.juzs.map(\.page), quran.juzs.map(\.firstVerse.page))
    }
}

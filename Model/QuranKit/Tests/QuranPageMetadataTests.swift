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

    func testNaskhReadingUsesSkippedPageMetadata() {
        let quran = Quran.hafsNaskh

        XCTAssertEqual(quran.numberOfPages, 611)
        XCTAssertEqual(quran.pagesToSkip, 1)
        XCTAssertEqual(quran.pages.count, 610)
        XCTAssertEqual(quran.pages.first?.pageNumber, 2)
        XCTAssertEqual(quran.pages.last?.pageNumber, 611)
        XCTAssertEqual(quran.pages.prefix(4).map(\.pageNumber), [2, 3, 4, 5])

        XCTAssertNil(Page(quran: quran, pageNumber: 1))
        XCTAssertNotNil(Page(quran: quran, pageNumber: 2))
        XCTAssertNotNil(Page(quran: quran, pageNumber: 611))
        XCTAssertNil(Page(quran: quran, pageNumber: 612))

        XCTAssertEqual(quran.suras[0].page.pageNumber, 2)
        XCTAssertEqual(quran.suras[1].page.pageNumber, 3)
        XCTAssertEqual(quran.suras[113].page.pageNumber, 611)
        XCTAssertEqual(quran.pages.last?.firstVerse.sura.suraNumber, 113)
        XCTAssertEqual(quran.pages.last?.firstVerse.ayah, 1)
        XCTAssertEqual(quran.pages.last?.lastVerse.sura.suraNumber, 114)
        XCTAssertEqual(quran.pages.last?.lastVerse.ayah, 6)
        XCTAssertTrue(quran.pages[0].isRightSide)
        XCTAssertFalse(quran.pages[1].isRightSide)
    }

    func testNaskhJuzPagesUseFirstVersePages() {
        let juzs = Quran.hafsNaskh.juzs

        XCTAssertEqual(juzs.map(\.page), juzs.map(\.firstVerse.page))
        XCTAssertEqual(
            juzs.map(\.page.pageNumber),
            [
                2, 23, 43, 63, 83, 103, 122, 143, 163, 183,
                202, 223, 243, 262, 283, 303, 323, 343, 363, 382,
                403, 423, 443, 463, 483, 503, 523, 543, 563, 587,
            ]
        )
    }

    func testNaskhReadingConfiguration() {
        XCTAssertTrue(Reading.allReadings.contains(.naskh))
        XCTAssertEqual(Reading.naskh.quran, .hafsNaskh)
        XCTAssertEqual(Reading.naskh.linePageMetrics, .naskhLinePages)
        XCTAssertEqual(Reading.naskh.linePageAssetWidth, 1342)
        XCTAssertEqual(Reading.naskh.imageAssetWidth, 1342)
        XCTAssertTrue(Reading.naskh.usesLinePageDividers)
        XCTAssertTrue(Reading.naskh.usesLinePageSidelines)
        XCTAssertTrue(Reading.naskh.usesInvertedQuranImageRenderingInDarkMode)
    }

    func testOnlyNaskhEnablesOptionalLinePageOverlays() {
        for reading in Reading.allReadings where reading != .naskh {
            XCTAssertFalse(reading.usesLinePageDividers, "\(reading)")
            XCTAssertFalse(reading.usesLinePageSidelines, "\(reading)")
        }

        XCTAssertTrue(Reading.naskh.usesLinePageDividers)
        XCTAssertTrue(Reading.naskh.usesLinePageSidelines)
    }

    func testSkippedPageReadingExcludesSkippedPagesFromVisiblePages() {
        let quran = Quran(raw: SkippedFirstPageReadingInfoRawData())

        XCTAssertEqual(quran.numberOfPages, 605)
        XCTAssertEqual(quran.pagesToSkip, 1)
        XCTAssertEqual(quran.pages.count, 604)
        XCTAssertEqual(quran.pages.first?.pageNumber, 2)
        XCTAssertEqual(quran.pages.last?.pageNumber, 605)
        XCTAssertEqual(quran.pages.prefix(4).map(\.pageNumber), [2, 3, 4, 5])

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

    func testPageSideUsesVisiblePagePosition() {
        let madaniQuran = Quran.hafsMadani1405
        XCTAssertTrue(madaniQuran.pages[0].isRightSide)
        XCTAssertFalse(madaniQuran.pages[1].isRightSide)

        let skippedQuran = Quran(raw: SkippedFirstPageReadingInfoRawData())
        XCTAssertEqual(skippedQuran.pages[0].pageNumber, 2)
        XCTAssertTrue(skippedQuran.pages[0].isRightSide)
        XCTAssertFalse(skippedQuran.pages[1].isRightSide)
    }

    func testPageMapperKeepsSameQuranPageNumber() {
        let quran = Quran.hafsMadani1405
        let mapper = QuranPageMapper(destination: quran)

        XCTAssertEqual(mapper.mapPage(quran.pages[0])?.pageNumber, 1)
        XCTAssertEqual(mapper.mapPage(quran.pages[1])?.pageNumber, 2)
        XCTAssertEqual(mapper.mapPage(quran.pages[603])?.pageNumber, 604)
    }

    func testPageMapperMapsSourcePageFirstVerseToDestinationPage() {
        let sourceQuran = Quran.hafsMadani1405
        let destinationQuran = Quran(raw: SkippedFirstPageReadingInfoRawData())
        let mapper = QuranPageMapper(destination: destinationQuran)

        let sourcePage = sourceQuran.pages[1]
        let mappedPage = mapper.mapPage(sourcePage)
        let mappedAyah = mapper.mapAyah(sourcePage.firstVerse)

        XCTAssertEqual(sourcePage.pageNumber, 2)
        XCTAssertEqual(mappedPage?.pageNumber, 3)
        XCTAssertEqual(mappedPage, mappedAyah?.page)
    }

    func testPageMapperMapsSkippedPageBackToCanonicalPage() {
        let sourceQuran = Quran(raw: SkippedFirstPageReadingInfoRawData())
        let mapper = QuranPageMapper(destination: .hafsMadani1405)

        XCTAssertEqual(mapper.mapPage(sourceQuran.pages[0])?.pageNumber, 1)
        XCTAssertEqual(mapper.mapPage(sourceQuran.pages[1])?.pageNumber, 2)
    }

    func testPageMapperMapsNaskhPageBackToCanonicalPage() {
        let mapper = QuranPageMapper(destination: .hafsMadani1405)

        XCTAssertEqual(mapper.mapPage(Quran.hafsNaskh.pages[0])?.pageNumber, 1)
        XCTAssertEqual(mapper.mapPage(Quran.hafsNaskh.pages[1])?.pageNumber, 2)
    }

    func testPageMapperMapsAyahBackedStateToDestinationAyah() {
        let sourceQuran = Quran.hafsMadani1405
        let destinationQuran = Quran(raw: SkippedFirstPageReadingInfoRawData())
        let mapper = QuranPageMapper(destination: destinationQuran)

        let firstAyah = AyahNumber(quran: sourceQuran, sura: 1, ayah: 1)!
        let secondSuraFirstAyah = AyahNumber(quran: sourceQuran, sura: 2, ayah: 1)!

        XCTAssertEqual(mapper.mapAyah(firstAyah)?.page.pageNumber, 2)
        XCTAssertEqual(mapper.mapAyah(secondSuraFirstAyah)?.page.pageNumber, 3)
    }
}

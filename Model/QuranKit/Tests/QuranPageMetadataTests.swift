//
//  QuranPageMetadataTests.swift
//
//
//  Created by OpenAI on 2026-04-25.
//

import XCTest
@testable import QuranKit

final class QuranPageMetadataTests: XCTestCase {
    private struct SupportedQuran {
        let name: String
        let quran: Quran
    }

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

    func testIndoPakReadingUsesSkippedPageMetadata() {
        let quran = Quran.hafsIndoPak

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

    func testIndoPakJuzPagesUseFirstVersePages() {
        let juzs = Quran.hafsIndoPak.juzs

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

    func testIndoPakReadingConfiguration() {
        XCTAssertTrue(Reading.allReadings.contains(.indoPak))
        XCTAssertEqual(Reading.indoPak.quran, .hafsIndoPak)
        XCTAssertEqual(Reading.indoPak.linePageMetrics, .indoPakLinePages)
        XCTAssertEqual(Reading.indoPak.linePageAssetWidth, 1342)
        XCTAssertEqual(Reading.indoPak.imageAssetWidth, 1342)
        XCTAssertTrue(Reading.indoPak.usesLinePageDividers)
        XCTAssertTrue(Reading.indoPak.usesLinePageSidelines)
        XCTAssertTrue(Reading.indoPak.usesInvertedQuranImageRenderingInDarkMode)
    }

    func testOnlyIndoPakEnablesOptionalLinePageOverlays() {
        for reading in Reading.allReadings where reading != .indoPak {
            XCTAssertFalse(reading.usesLinePageDividers, "\(reading)")
            XCTAssertFalse(reading.usesLinePageSidelines, "\(reading)")
        }

        XCTAssertTrue(Reading.indoPak.usesLinePageDividers)
        XCTAssertTrue(Reading.indoPak.usesLinePageSidelines)
    }

    func testPageMushafMatchesEveryReadingPageLayout() {
        XCTAssertEqual(QuranPageMushaf.madani1405.rawValue, 0)
        XCTAssertEqual(QuranPageMushaf.madani1440.rawValue, 1)
        XCTAssertEqual(QuranPageMushaf.indoPak.rawValue, 2)

        for reading in Reading.allReadings {
            let expectedMushaf: QuranPageMushaf = switch reading {
            case .hafs_1405, .tajweed:
                .madani1405
            case .hafs_1421, .hafs_1439, .hafs_1440, .hafs_1441:
                .madani1440
            case .indoPak:
                .indoPak
            }
            XCTAssertEqual(reading.quran.pageMushaf, expectedMushaf)
        }
    }

    func testPageMapperPreservesTheSourceMadaniLayout() throws {
        let mapper = QuranPageMapper(destination: .hafsIndoPak)

        let madani1405Page = try XCTUnwrap(mapper.mapPage(Page(
            quran: .hafsMadani1405,
            pageNumber: 585
        )!))
        let madani1440Page = try XCTUnwrap(mapper.mapPage(Page(
            quran: .hafsMadani1440,
            pageNumber: 585
        )!))

        XCTAssertEqual(madani1405Page.pageNumber, 591)
        XCTAssertEqual(madani1440Page.pageNumber, 590)
    }

    func testSkippedPageReadingExcludesSkippedPagesFromVisiblePages() {
        let quran = Quran(
            raw: SkippedFirstPageReadingInfoRawData(),
            pageMushaf: .madani1405
        )

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
        let quran = Quran(
            raw: SkippedFirstPageReadingInfoRawData(),
            pageMushaf: .madani1405
        )

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

        let skippedQuran = Quran(
            raw: SkippedFirstPageReadingInfoRawData(),
            pageMushaf: .madani1405
        )
        XCTAssertEqual(skippedQuran.pages[0].pageNumber, 2)
        XCTAssertTrue(skippedQuran.pages[0].isRightSide)
        XCTAssertFalse(skippedQuran.pages[1].isRightSide)
    }

    func testPageMapperKeepsEveryPageInTheSameSupportedLayout() {
        for supportedQuran in supportedQurans {
            let mapper = QuranPageMapper(destination: supportedQuran.quran)

            for page in supportedQuran.quran.pages {
                XCTAssertEqual(
                    mapper.mapPage(page),
                    page,
                    "\(supportedQuran.name) page \(page.pageNumber)"
                )
            }
        }
    }

    func testPageMapperMapsEveryPageBetweenEverySupportedLayout() throws {
        for source in supportedQurans {
            for destination in supportedQurans {
                let mapper = QuranPageMapper(destination: destination.quran)

                for sourcePage in source.quran.pages {
                    let context = "\(source.name) page \(sourcePage.pageNumber) → \(destination.name)"
                    let mappedPage = try XCTUnwrap(mapper.mapPage(sourcePage), context)

                    XCTAssertEqual(mappedPage.quran, destination.quran, context)
                    XCTAssertTrue(pagesOverlap(sourcePage, mappedPage), context)
                }
            }
        }
    }

    func testPageMapperUsesRoundTripCandidateForEveryPageBetweenEverySupportedLayout() throws {
        for source in supportedQurans {
            for destination in supportedQurans {
                let destinationMapper = QuranPageMapper(destination: destination.quran)
                let sourceMapper = QuranPageMapper(destination: source.quran)

                for sourcePage in source.quran.pages {
                    let context = "\(source.name) page \(sourcePage.pageNumber) → \(destination.name)"
                    let mappedPage = try XCTUnwrap(destinationMapper.mapPage(sourcePage), context)
                    let candidates = try candidatePages(
                        for: sourcePage,
                        mapper: destinationMapper,
                        destination: destination.quran,
                        context: context
                    )
                    let roundTripCandidates = candidates.filter { candidate in
                        sourceMapper.mapAyah(representativeAyah(on: candidate))?.page == sourcePage
                    }

                    if !roundTripCandidates.isEmpty {
                        XCTAssertTrue(roundTripCandidates.contains(mappedPage), context)
                    }
                }
            }
        }
    }

    func testPageMapperMapsSourcePageFirstVerseToDestinationPage() {
        let sourceQuran = Quran.hafsMadani1405
        let destinationQuran = Quran(
            raw: SkippedFirstPageReadingInfoRawData(),
            pageMushaf: .madani1405
        )
        let mapper = QuranPageMapper(destination: destinationQuran)

        let sourcePage = sourceQuran.pages[1]
        let mappedPage = mapper.mapPage(sourcePage)
        let mappedAyah = mapper.mapAyah(sourcePage.firstVerse)

        XCTAssertEqual(sourcePage.pageNumber, 2)
        XCTAssertEqual(mappedPage?.pageNumber, 3)
        XCTAssertEqual(mappedPage, mappedAyah?.page)
    }

    func testPageMapperPreservesMadani1440PageAcrossCanonicalRoundTrip() throws {
        let sourceQuran = Quran.hafsMadani1440
        let canonicalQuran = Quran.hafsMadani1405
        let sourcePage = try XCTUnwrap(Page(quran: sourceQuran, pageNumber: 534))

        let canonicalPage = try XCTUnwrap(QuranPageMapper(destination: canonicalQuran).mapPage(sourcePage))
        let restoredPage = QuranPageMapper(destination: sourceQuran).mapPage(canonicalPage)

        XCTAssertEqual(canonicalPage.pageNumber, 534)
        XCTAssertEqual(restoredPage, sourcePage)
    }

    func testPageMapperRoundTripsEveryPageBetweenEqualSizedSupportedLayouts() throws {
        for source in supportedQurans {
            for destination in supportedQurans {
                guard destination.quran.pages.count == source.quran.pages.count else {
                    continue
                }

                let destinationMapper = QuranPageMapper(destination: destination.quran)
                let sourceMapper = QuranPageMapper(destination: source.quran)

                for sourcePage in source.quran.pages {
                    let context = "\(source.name) page \(sourcePage.pageNumber) → \(destination.name)"
                    let destinationPage = try XCTUnwrap(destinationMapper.mapPage(sourcePage), context)
                    XCTAssertEqual(sourceMapper.mapPage(destinationPage), sourcePage, context)
                }
            }
        }
    }

    func testPageMapperMapsSkippedPageBackToCanonicalPage() {
        let sourceQuran = Quran(
            raw: SkippedFirstPageReadingInfoRawData(),
            pageMushaf: .madani1405
        )
        let mapper = QuranPageMapper(destination: .hafsMadani1405)

        XCTAssertEqual(mapper.mapPage(sourceQuran.pages[0])?.pageNumber, 1)
        XCTAssertEqual(mapper.mapPage(sourceQuran.pages[1])?.pageNumber, 2)
    }

    func testPageMapperMapsIndoPakPageBackToCanonicalPage() {
        let mapper = QuranPageMapper(destination: .hafsMadani1405)

        XCTAssertEqual(mapper.mapPage(Quran.hafsIndoPak.pages[0])?.pageNumber, 1)
        XCTAssertEqual(mapper.mapPage(Quran.hafsIndoPak.pages[1])?.pageNumber, 2)
    }

    func testPageMapperMapsAyahBackedStateToDestinationAyah() {
        let sourceQuran = Quran.hafsMadani1405
        let destinationQuran = Quran(
            raw: SkippedFirstPageReadingInfoRawData(),
            pageMushaf: .madani1405
        )
        let mapper = QuranPageMapper(destination: destinationQuran)

        let firstAyah = AyahNumber(quran: sourceQuran, sura: 1, ayah: 1)!
        let secondSuraFirstAyah = AyahNumber(quran: sourceQuran, sura: 2, ayah: 1)!

        XCTAssertEqual(mapper.mapAyah(firstAyah)?.page.pageNumber, 2)
        XCTAssertEqual(mapper.mapAyah(secondSuraFirstAyah)?.page.pageNumber, 3)
    }

    // MARK: Private

    private var supportedQurans: [SupportedQuran] {
        var seenQurans = Set<Quran>()
        return Reading.allReadings.compactMap { reading in
            guard seenQurans.insert(reading.quran).inserted else {
                return nil
            }
            return SupportedQuran(name: String(describing: reading), quran: reading.quran)
        }
    }

    private func candidatePages(
        for sourcePage: Page,
        mapper: QuranPageMapper,
        destination: Quran,
        context: String
    ) throws -> [Page] {
        let firstPage = try XCTUnwrap(mapper.mapAyah(sourcePage.firstVerse)?.page, context)
        let lastPage = try XCTUnwrap(mapper.mapAyah(sourcePage.lastVerse)?.page, context)
        let pageNumbers = min(firstPage.pageNumber, lastPage.pageNumber) ...
            max(firstPage.pageNumber, lastPage.pageNumber)
        return pageNumbers.compactMap { Page(quran: destination, pageNumber: $0) }
    }

    private func representativeAyah(on page: Page) -> AyahNumber {
        let verses = page.verses
        return verses[(verses.count - 1) / 2]
    }

    private func pagesOverlap(_ sourcePage: Page, _ destinationPage: Page) -> Bool {
        guard let destinationFirstAyah = AyahNumber(
            quran: sourcePage.quran,
            sura: destinationPage.firstVerse.sura.suraNumber,
            ayah: destinationPage.firstVerse.ayah
        ),
            let destinationLastAyah = AyahNumber(
                quran: sourcePage.quran,
                sura: destinationPage.lastVerse.sura.suraNumber,
                ayah: destinationPage.lastVerse.ayah
            )
        else {
            return false
        }

        return destinationFirstAyah <= sourcePage.lastVerse &&
            sourcePage.firstVerse <= destinationLastAyah
    }
}

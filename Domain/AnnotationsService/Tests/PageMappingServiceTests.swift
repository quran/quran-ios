//
//  PageMappingServiceTests.swift
//  Quran
//
//  Created by OpenAI on 2026-04-25.
//

import Combine
import XCTest
@testable import AnnotationsService
@testable import LastPagePersistence
@testable import PageBookmarkPersistence
@testable import QuranAnnotations
@testable import QuranKit

@MainActor
final class PageMappingServiceTests: XCTestCase {
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

    func testPageBookmarksMapsStoredCanonicalPagesToRequestedQuran() {
        let persistence = PageBookmarkPersistenceFake(bookmarks: [
            PageBookmarkPersistenceModel(page: storedPage(1), creationDate: date),
        ])
        let service = PageBookmarkService(persistence: persistence)
        let quran = skippedPageQuran()

        let bookmarks = value(from: service.pageBookmarks(quran: quran))

        XCTAssertEqual(bookmarks.map(\.page.pageNumber), [2])
        XCTAssertEqual(bookmarks.map(\.creationDate), [date])
    }

    func testPageBookmarksDeduplicatePagesAfterMapping() throws {
        let sourceQuran = Quran.hafsIndoPak
        let destinationQuran = Quran.hafsMadani1405
        let mapper = QuranPageMapper(destination: destinationQuran)
        let sourcePagesByDestination = Dictionary(grouping: sourceQuran.pages) { mapper.mapPage($0) }
        let duplicateSourcePages = try XCTUnwrap(
            sourcePagesByDestination.first(where: { $0.key != nil && $0.value.count > 1 })?.value
        )
        let olderPage = duplicateSourcePages[0]
        let newerPage = duplicateSourcePages[1]
        let persistence = PageBookmarkPersistenceFake(bookmarks: [
            PageBookmarkPersistenceModel(page: olderPage, creationDate: date),
            PageBookmarkPersistenceModel(page: newerPage, creationDate: laterDate),
        ])
        let service = PageBookmarkService(persistence: persistence)

        let bookmarks = value(from: service.pageBookmarks(quran: destinationQuran))

        XCTAssertEqual(bookmarks.count, 1)
        XCTAssertEqual(bookmarks.first?.page, mapper.mapPage(newerPage))
        XCTAssertEqual(bookmarks.first?.creationDate, laterDate)
        XCTAssertEqual(
            try XCTUnwrap(bookmarks.first).storedPages,
            Set(duplicateSourcePages)
        )
    }

    func testInsertPageBookmarkStoresExactPageLayout() async throws {
        let persistence = PageBookmarkPersistenceFake()
        let service = PageBookmarkService(persistence: persistence)
        let page = try XCTUnwrap(Page(quran: .hafsMadani1440, pageNumber: 534))

        try await service.insertPageBookmark(page)

        XCTAssertEqual(persistence.insertedPages, [storedPage(534, mushaf: .madani1440)])
    }

    func testRemovePageBookmarkRemovesCanonicalPage() async throws {
        let persistence = PageBookmarkPersistenceFake(bookmarks: [
            PageBookmarkPersistenceModel(page: storedPage(1), creationDate: date),
        ])
        let service = PageBookmarkService(persistence: persistence)
        let bookmark = try XCTUnwrap(value(from: service.pageBookmarks(quran: skippedPageQuran())).first)

        try await service.removePageBookmark(bookmark)

        XCTAssertEqual(persistence.removedPages, [storedPage(1)])
    }

    func testInsertPageBookmarkPreservesExactPageAcrossDifferentPageLayouts() async throws {
        let persistence = PageBookmarkPersistenceFake()
        let service = PageBookmarkService(persistence: persistence)
        let quran = Quran.hafsMadani1440
        let page = try XCTUnwrap(Page(quran: quran, pageNumber: 534))

        try await service.insertPageBookmark(page)
        let bookmarks = value(from: service.pageBookmarks(quran: quran))

        XCTAssertEqual(persistence.insertedPages, [storedPage(534, mushaf: .madani1440)])
        XCTAssertEqual(bookmarks.map(\.page), [page])
    }

    func testMadaniLayoutsWithSamePageNumberMapIndependentlyToIndoPak() {
        let persistence = PageBookmarkPersistenceFake(bookmarks: [
            PageBookmarkPersistenceModel(page: storedPage(585), creationDate: date),
            PageBookmarkPersistenceModel(page: storedPage(585, mushaf: .madani1440), creationDate: laterDate),
        ])
        let service = PageBookmarkService(persistence: persistence)

        let bookmarks = value(from: service.pageBookmarks(quran: .hafsIndoPak))

        XCTAssertEqual(Set(bookmarks.map(\.page.pageNumber)), [590, 591])
        XCTAssertEqual(
            Set(bookmarks.flatMap(\.storedPages)),
            [storedPage(585), storedPage(585, mushaf: .madani1440)]
        )
    }

    func testRemovePageBookmarkRemovesLegacyStoredPageThatMapsToDisplayedPage() async throws {
        let persistence = PageBookmarkPersistenceFake(bookmarks: [
            PageBookmarkPersistenceModel(page: storedPage(534), creationDate: date),
        ])
        let service = PageBookmarkService(persistence: persistence)
        let quran = Quran.hafsMadani1440
        let displayedBookmark = try XCTUnwrap(value(from: service.pageBookmarks(quran: quran)).first)

        try await service.removePageBookmark(displayedBookmark)
        let bookmarks = value(from: service.pageBookmarks(quran: quran))

        XCTAssertTrue(bookmarks.isEmpty)
    }

    func testAdjacentCanonicalBookmarksRemainDistinctAfterMapping() async throws {
        let persistence = PageBookmarkPersistenceFake(bookmarks: [
            PageBookmarkPersistenceModel(page: storedPage(531), creationDate: date),
            PageBookmarkPersistenceModel(page: storedPage(532), creationDate: laterDate),
        ])
        let service = PageBookmarkService(persistence: persistence)
        let quran = Quran.hafsMadani1440
        let displayedBookmarks = value(from: service.pageBookmarks(quran: quran))

        XCTAssertEqual(displayedBookmarks.map(\.page.pageNumber), [532, 531])

        try await service.removePageBookmark(try XCTUnwrap(displayedBookmarks.first))
        let bookmarks = value(from: service.pageBookmarks(quran: quran))

        XCTAssertEqual(bookmarks.map(\.page.pageNumber), [531])
    }

    func testIndoPakBookmarkPreservesAndRemovesItsNativePageAfterMadaniPresentation() async throws {
        let sourcePage = try irreversibleIndoPakPage()
        let persistence = PageBookmarkPersistenceFake()
        let service = PageBookmarkService(persistence: persistence)

        try await service.insertPageBookmark(sourcePage)
        let madaniBookmark = try XCTUnwrap(
            value(from: service.pageBookmarks(quran: .hafsMadani1405)).first
        )

        XCTAssertEqual(
            persistence.insertedPages,
            [sourcePage]
        )
        XCTAssertEqual(
            madaniBookmark.storedPages,
            [sourcePage]
        )

        try await service.removePageBookmark(madaniBookmark)

        XCTAssertEqual(
            persistence.removedPages,
            [sourcePage]
        )
        XCTAssertTrue(persistence.bookmarks.isEmpty)
    }

    func testRemovingGroupedBookmarkDeletesEveryStoredPage() async throws {
        let indoPakPage = try irreversibleIndoPakPage()
        let madaniPage = try XCTUnwrap(
            QuranPageMapper(destination: .hafsMadani1405).mapPage(indoPakPage)
        )
        let expectedPages: Set<Page> = [
            indoPakPage,
            madaniPage,
        ]
        let persistence = PageBookmarkPersistenceFake(bookmarks: [
            PageBookmarkPersistenceModel(
                page: indoPakPage,
                creationDate: date
            ),
            PageBookmarkPersistenceModel(
                page: madaniPage,
                creationDate: laterDate
            ),
        ])
        let service = PageBookmarkService(persistence: persistence)
        let bookmark = try XCTUnwrap(
            value(from: service.pageBookmarks(quran: .hafsMadani1405)).first
        )

        XCTAssertEqual(bookmark.storedPages, expectedPages)

        try await service.removePageBookmark(bookmark)

        XCTAssertEqual(persistence.removalCalls.count, 1)
        XCTAssertEqual(try XCTUnwrap(persistence.removalCalls.first), expectedPages)
        XCTAssertTrue(persistence.bookmarks.isEmpty)
    }

    #if !QURAN_SYNC
    func testLastPagesMapStoredCanonicalPagesToRequestedQuran() async throws {
        let quran = skippedPageQuran()
        let persistence = LastPagePersistenceFake(lastPages: [
            LastPagePersistenceModel(page: storedPage(1), createdOn: date, modifiedOn: laterDate),
        ])
        let service = PersistenceLastPageService(persistence: persistence)

        var iterator = service.lastPages(quran: quran).makeAsyncIterator()
        let nextLastPages = try await iterator.next()
        let lastPages = try XCTUnwrap(nextLastPages)

        XCTAssertEqual(lastPages.map(\.id), [quran.pages[0]])
        XCTAssertEqual(lastPages.map(\.page.pageNumber), [2])
        XCTAssertEqual(lastPages.map(\.createdOn), [date])
        XCTAssertEqual(lastPages.map(\.modifiedOn), [laterDate])
    }

    func testAddLastPageStoresExactPageLayoutAndReturnsRequestedQuranPage() async throws {
        let persistence = LastPagePersistenceFake()
        let service = PersistenceLastPageService(persistence: persistence)
        let page = try XCTUnwrap(Page(quran: .hafsMadani1440, pageNumber: 534))

        let lastPage = try await service.add(page: page)

        XCTAssertEqual(persistence.addedPages, [storedPage(534, mushaf: .madani1440)])
        XCTAssertEqual(lastPage.id, page)
        XCTAssertEqual(lastPage.page, page)
    }

    func testUpdateLastPageStoresExactPageLayoutAndReturnsRequestedQuranPage() async throws {
        let persistence = LastPagePersistenceFake(lastPages: [
            LastPagePersistenceModel(
                page: storedPage(533, mushaf: .madani1440),
                createdOn: date,
                modifiedOn: laterDate
            ),
        ])
        let service = PersistenceLastPageService(persistence: persistence)
        let quran = Quran.hafsMadani1440
        var iterator = service.lastPages(quran: quran).makeAsyncIterator()
        let currentLastPages = try await iterator.next()
        let currentLastPage = try XCTUnwrap(currentLastPages?.first)
        let destinationPage = try XCTUnwrap(Page(quran: quran, pageNumber: 534))
        let lastPage = try await service.update(lastPage: currentLastPage, toPage: destinationPage)

        XCTAssertEqual(persistence.updates, [
            LastPagePersistenceFake.Update(
                sources: [storedPage(533, mushaf: .madani1440)],
                destination: storedPage(534, mushaf: .madani1440)
            ),
        ])
        XCTAssertEqual(lastPage.id, destinationPage)
        XCTAssertEqual(lastPage.page, destinationPage)
    }

    func testIndoPakLastPagePreservesNativePageAndUpdatesUsingStoredPage() async throws {
        let sourcePage = try irreversibleIndoPakPage()
        let persistence = LastPagePersistenceFake(lastPages: [
            LastPagePersistenceModel(
                page: sourcePage,
                createdOn: date,
                modifiedOn: laterDate
            ),
        ])
        let service = PersistenceLastPageService(persistence: persistence)
        var iterator = service.lastPages(quran: .hafsMadani1405).makeAsyncIterator()
        let presentedLastPages = try await iterator.next()
        let presentedLastPage = try XCTUnwrap(presentedLastPages?.first)
        let destinationPage = Quran.hafsMadani1405.pages[100]

        XCTAssertEqual(
            presentedLastPage.storedPages,
            [sourcePage]
        )

        _ = try await service.update(lastPage: presentedLastPage, toPage: destinationPage)

        XCTAssertEqual(persistence.updates, [
            LastPagePersistenceFake.Update(
                sources: [sourcePage],
                destination: destinationPage
            ),
        ])
    }

    func testGroupedLastPageUpdateReplacesEveryStoredPage() async throws {
        let indoPakPage = try irreversibleIndoPakPage()
        let madaniPage = try XCTUnwrap(
            QuranPageMapper(destination: .hafsMadani1405).mapPage(indoPakPage)
        )
        let expectedSources: Set<Page> = [
            indoPakPage,
            madaniPage,
        ]
        let persistence = LastPagePersistenceFake(lastPages: [
            LastPagePersistenceModel(
                page: indoPakPage,
                createdOn: date,
                modifiedOn: date
            ),
            LastPagePersistenceModel(
                page: madaniPage,
                createdOn: laterDate,
                modifiedOn: laterDate
            ),
        ])
        let service = PersistenceLastPageService(persistence: persistence)
        var iterator = service.lastPages(quran: .hafsMadani1405).makeAsyncIterator()
        let presentedLastPages = try await iterator.next()
        let presentedLastPage = try XCTUnwrap(presentedLastPages?.first)
        let destinationPage = Quran.hafsMadani1405.pages[100]

        XCTAssertEqual(presentedLastPage.storedPages, expectedSources)
        XCTAssertEqual(presentedLastPage.modifiedOn, laterDate)

        _ = try await service.update(lastPage: presentedLastPage, toPage: destinationPage)

        XCTAssertEqual(persistence.updates.count, 1)
        XCTAssertEqual(Set(persistence.updates[0].sources), expectedSources)
        XCTAssertEqual(persistence.updates[0].destination, destinationPage)
        XCTAssertEqual(persistence.lastPagesList.map(\.page), [destinationPage])
    }
    #endif

    // MARK: Private

    private let date = Date(timeIntervalSince1970: 1000)
    private let laterDate = Date(timeIntervalSince1970: 2000)

    private func skippedPageQuran() -> Quran {
        Quran(
            raw: SkippedFirstPageReadingInfoRawData(),
            pageMushaf: .madani1405
        )
    }

    private func storedPage(
        _ pageNumber: Int,
        mushaf: QuranPageMushaf = .madani1405
    ) -> Page {
        Page(quran: mushaf.quran, pageNumber: pageNumber)!
    }

    private func irreversibleIndoPakPage() throws -> Page {
        let madaniMapper = QuranPageMapper(destination: .hafsMadani1405)
        let indoPakMapper = QuranPageMapper(destination: .hafsIndoPak)
        return try XCTUnwrap(Quran.hafsIndoPak.pages.first { sourcePage in
            guard let madaniPage = madaniMapper.mapPage(sourcePage) else {
                return false
            }
            return indoPakMapper.mapPage(madaniPage) != sourcePage
        })
    }

    private func value<P: Publisher>(from publisher: P) -> P.Output where P.Failure == Never {
        var value: P.Output?
        let cancellable = publisher.sink { value = $0 }
        withExtendedLifetime(cancellable) {}
        return value!
    }
}

final class PageBookmarkPersistenceFake: PageBookmarkPersistence {
    // MARK: Lifecycle

    init(bookmarks: [PageBookmarkPersistenceModel] = []) {
        self.bookmarks = bookmarks
    }

    // MARK: Internal

    var bookmarks: [PageBookmarkPersistenceModel]
    private(set) var insertedPages: [Page] = []
    private(set) var removalCalls: [Set<Page>] = []

    var removedPages: Set<Page> {
        removalCalls.reduce(into: []) { $0.formUnion($1) }
    }

    func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        Just(bookmarks).eraseToAnyPublisher()
    }

    func insertPageBookmark(at page: Page) async throws {
        insertedPages.append(page)
        bookmarks.append(PageBookmarkPersistenceModel(page: page, creationDate: Date()))
    }

    func removePageBookmarks(at pages: Set<Page>) async throws {
        removalCalls.append(pages)
        bookmarks.removeAll { pages.contains($0.page) }
    }

    func removeAllPageBookmarks() async throws {
        bookmarks.removeAll()
    }
}

#if !QURAN_SYNC
final class LastPagePersistenceFake: LastPagePersistence, @unchecked Sendable {
    struct Update: Equatable {
        let sources: Set<Page>
        let destination: Page
    }

    // MARK: Lifecycle

    init(lastPages: [LastPagePersistenceModel] = []) {
        lastPagesList = lastPages
    }

    // MARK: Internal

    private(set) var lastPagesList: [LastPagePersistenceModel]
    private(set) var addedPages: [Page] = []
    private(set) var updates: [Update] = []

    func lastPages() -> AnyPublisher<[LastPagePersistenceModel], Never> {
        Just(lastPagesList).eraseToAnyPublisher()
    }

    func retrieveAll() async throws -> [LastPagePersistenceModel] {
        lastPagesList
    }

    func add(at page: Page) async throws -> LastPagePersistenceModel {
        addedPages.append(page)
        let model = LastPagePersistenceModel(
            page: page,
            createdOn: Date(timeIntervalSince1970: 1000),
            modifiedOn: Date(timeIntervalSince1970: 2000)
        )
        lastPagesList.append(model)
        return model
    }

    func update(
        pages: Set<Page>,
        to destination: Page
    ) async throws -> LastPagePersistenceModel {
        updates.append(Update(sources: pages, destination: destination))
        let model = LastPagePersistenceModel(
            page: destination,
            createdOn: Date(timeIntervalSince1970: 1000),
            modifiedOn: Date(timeIntervalSince1970: 2000)
        )
        lastPagesList.removeAll { pages.contains($0.page) }
        lastPagesList.removeAll { $0.page == destination }
        lastPagesList.append(model)
        return model
    }
}
#endif

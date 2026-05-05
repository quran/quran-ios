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
            PageBookmarkPersistenceModel(page: 1, creationDate: date),
        ])
        let service = PageBookmarkService(persistence: persistence)
        let quran = skippedPageQuran()

        let bookmarks = value(from: service.pageBookmarks(quran: quran))

        XCTAssertEqual(bookmarks.map(\.page.pageNumber), [2])
        XCTAssertEqual(bookmarks.map(\.creationDate), [date])
    }

    func testInsertPageBookmarkStoresCanonicalPage() async throws {
        let persistence = PageBookmarkPersistenceFake()
        let service = PageBookmarkService(persistence: persistence)

        try await service.insertPageBookmark(skippedPageQuran().pages[0])

        XCTAssertEqual(persistence.insertedPages, [1])
    }

    func testRemovePageBookmarkRemovesCanonicalPage() async throws {
        let persistence = PageBookmarkPersistenceFake()
        let service = PageBookmarkService(persistence: persistence)

        try await service.removePageBookmark(skippedPageQuran().pages[0])

        XCTAssertEqual(persistence.removedPages, [1])
    }

    func testPageBookmarksIgnoreInvalidStoredPages() {
        let persistence = PageBookmarkPersistenceFake(bookmarks: [
            PageBookmarkPersistenceModel(page: 1, creationDate: date),
            PageBookmarkPersistenceModel(page: 605, creationDate: date),
        ])
        let service = PageBookmarkService(persistence: persistence)

        let bookmarks = value(from: service.pageBookmarks(quran: skippedPageQuran()))

        XCTAssertEqual(bookmarks.map(\.page.pageNumber), [2])
    }

    func testLastPagesMapStoredCanonicalPagesToRequestedQuran() {
        let persistence = LastPagePersistenceFake(lastPages: [
            LastPagePersistenceModel(page: 1, createdOn: date, modifiedOn: laterDate),
        ])
        let service = PersistenceLastPageService(persistence: persistence)

        let lastPages = value(from: service.lastPages(quran: skippedPageQuran()))

        XCTAssertEqual(lastPages.map(\.page.pageNumber), [2])
        XCTAssertEqual(lastPages.map(\.createdOn), [date])
        XCTAssertEqual(lastPages.map(\.modifiedOn), [laterDate])
    }

    func testAddLastPageStoresCanonicalPageAndReturnsRequestedQuranPage() async throws {
        let persistence = LastPagePersistenceFake()
        let service = PersistenceLastPageService(persistence: persistence)

        let lastPage = try await service.add(page: skippedPageQuran().pages[0])

        XCTAssertEqual(persistence.addedPages, [1])
        XCTAssertEqual(lastPage.page.pageNumber, 2)
    }

    func testUpdateLastPageStoresCanonicalPagesAndReturnsRequestedQuranPage() async throws {
        let persistence = LastPagePersistenceFake()
        let service = PersistenceLastPageService(persistence: persistence)
        let quran = skippedPageQuran()

        let lastPage = try await service.update(page: quran.pages[0], toPage: quran.pages[1])

        XCTAssertEqual(persistence.updates, [LastPagePersistenceFake.Update(page: 1, toPage: 2)])
        XCTAssertEqual(lastPage.page.pageNumber, 3)
    }

    // MARK: Private

    private let date = Date(timeIntervalSince1970: 1000)
    private let laterDate = Date(timeIntervalSince1970: 2000)

    private func skippedPageQuran() -> Quran {
        Quran(raw: SkippedFirstPageReadingInfoRawData())
    }

    private func value<P: Publisher>(from publisher: P) -> P.Output where P.Failure == Never {
        var value: P.Output?
        let cancellable = publisher.sink { value = $0 }
        withExtendedLifetime(cancellable) {}
        return value!
    }
}

private final class PageBookmarkPersistenceFake: PageBookmarkPersistence {
    // MARK: Lifecycle

    init(bookmarks: [PageBookmarkPersistenceModel] = []) {
        self.bookmarks = bookmarks
    }

    // MARK: Internal

    var bookmarks: [PageBookmarkPersistenceModel]
    private(set) var insertedPages: [Int] = []
    private(set) var removedPages: [Int] = []

    func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        Just(bookmarks).eraseToAnyPublisher()
    }

    func insertPageBookmark(_ page: Int) async throws {
        insertedPages.append(page)
    }

    func removePageBookmark(_ page: Int) async throws {
        removedPages.append(page)
    }

    func removeAllPageBookmarks() async throws {
        bookmarks.removeAll()
    }
}

private final class LastPagePersistenceFake: LastPagePersistence, @unchecked Sendable {
    struct Update: Equatable {
        let page: Int
        let toPage: Int
    }

    // MARK: Lifecycle

    init(lastPages: [LastPagePersistenceModel] = []) {
        lastPagesList = lastPages
    }

    // MARK: Internal

    private(set) var lastPagesList: [LastPagePersistenceModel]
    private(set) var addedPages: [Int] = []
    private(set) var updates: [Update] = []

    func lastPages() -> AnyPublisher<[LastPagePersistenceModel], Never> {
        Just(lastPagesList).eraseToAnyPublisher()
    }

    func retrieveAll() async throws -> [LastPagePersistenceModel] {
        lastPagesList
    }

    func add(page: Int) async throws -> LastPagePersistenceModel {
        addedPages.append(page)
        let model = LastPagePersistenceModel(
            page: page,
            createdOn: Date(timeIntervalSince1970: 1000),
            modifiedOn: Date(timeIntervalSince1970: 2000)
        )
        lastPagesList.append(model)
        return model
    }

    func update(page: Int, toPage: Int) async throws -> LastPagePersistenceModel {
        updates.append(Update(page: page, toPage: toPage))
        let model = LastPagePersistenceModel(
            page: toPage,
            createdOn: Date(timeIntervalSince1970: 1000),
            modifiedOn: Date(timeIntervalSince1970: 2000)
        )
        lastPagesList.append(model)
        return model
    }
}

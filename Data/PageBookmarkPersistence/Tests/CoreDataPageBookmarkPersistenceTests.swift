//
//  CoreDataPageBookmarkPersistenceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-31.
//

import AsyncUtilitiesForTesting
import Combine
import CoreDataPersistence
import CoreDataPersistenceTestSupport
import QuranKit
import XCTest
@testable import PageBookmarkPersistence

final class CoreDataPageBookmarkPersistenceTests: XCTestCase {
    var persistence: CoreDataPageBookmarkPersistence!
    var stack: CoreDataStack!
    var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        stack = CoreDataStack.testingStack()
        persistence = CoreDataPageBookmarkPersistence(stack: stack)
    }

    override func tearDown() {
        super.tearDown()
        // Clean up any resources here
        CoreDataStack.removePersistentFiles()
        persistence = nil
        stack = nil
        subscriptions.removeAll()
    }

    func testInsertAndRetrievePageBookmarks() async throws {
        // 1. Insert some page bookmarks to the persistence
        let pages = [1, 2, 300]

        for pageNumber in pages {
            try await persistence.insertPageBookmark(at: page(pageNumber))
        }

        // 2. Fetch the page bookmarks using pageBookmarks()
        let collector = PublisherCollector(persistence.pageBookmarks())

        // 3. Verify that the returned page bookmarks match what you expect
        XCTAssertEqual(collector.items.count, 1)
        XCTAssertEqual(collector.items.last?.map(\.page.pageNumber), [300, 2, 1])
        XCTAssertEqual(
            collector.items.last?.map(\.page.quran.pageMushaf),
            [.madani1405, .madani1405, .madani1405]
        )

        // 4. Insert more
        try await persistence.insertPageBookmark(at: page(45))
        XCTAssertEqual(collector.items.last?.map(\.page.pageNumber), [45, 300, 2, 1])

        // 5. Remove a page bookmark
        try await persistence.removePageBookmarks(at: [page(2)])
        XCTAssertEqual(collector.items.last?.map(\.page.pageNumber), [45, 300, 1])

        // 6. Remove another page bookmark
        try await persistence.removePageBookmarks(at: [page(45)])
        XCTAssertEqual(collector.items.last?.map(\.page.pageNumber), [300, 1])

        // 7. Verify new collectors return same result
        let newcollector = PublisherCollector(persistence.pageBookmarks())
        XCTAssertEqual(newcollector.items.last?.map(\.page.pageNumber), [300, 1])
    }

    func testSamePageInEveryMushafIsStoredAndRemovedIndependently() async throws {
        let collector = PublisherCollector(persistence.pageBookmarks())

        try await persistence.insertPageBookmark(at: page(300))
        try await persistence.insertPageBookmark(at: page(300, mushaf: .madani1440))
        try await persistence.insertPageBookmark(at: page(300, mushaf: .indoPak))

        XCTAssertEqual(
            collector.items.last?.map(\.page.quran.pageMushaf),
            [.indoPak, .madani1440, .madani1405]
        )

        try await persistence.removePageBookmarks(at: [page(300, mushaf: .madani1440)])

        XCTAssertEqual(collector.items.last?.map(\.page.quran.pageMushaf), [.indoPak, .madani1405])

        try await persistence.removePageBookmarks(at: [page(300, mushaf: .indoPak)])

        XCTAssertEqual(collector.items.last?.map(\.page.quran.pageMushaf), [.madani1405])
    }

    func testRemovePageBookmarksDeletesEveryRequestedPage() async throws {
        let collector = PublisherCollector(persistence.pageBookmarks())
        try await persistence.insertPageBookmark(at: page(300))
        try await persistence.insertPageBookmark(at: page(300, mushaf: .madani1440))
        try await persistence.insertPageBookmark(at: page(300, mushaf: .indoPak))

        try await persistence.removePageBookmarks(at: [
            page(300),
            page(300, mushaf: .madani1440),
            page(300, mushaf: .indoPak),
        ])

        XCTAssertTrue(collector.items.last?.isEmpty == true)
    }

    func testPageBookmarksIgnoreInvalidStoredPages() throws {
        let context = stack.viewContext
        _ = context.newPageBookmark(page: 605, modifiedOn: 1)
        try context.save()

        let collector = PublisherCollector(persistence.pageBookmarks())

        XCTAssertTrue(collector.items.last?.isEmpty == true)
    }

    private func page(
        _ pageNumber: Int,
        mushaf: QuranPageMushaf = .madani1405
    ) -> Page {
        Page(quran: mushaf.quran, pageNumber: pageNumber)!
    }
}

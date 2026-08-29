//
//  CoreDataLastPagePersistenceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-30.
//

import AsyncUtilitiesForTesting
import Combine
import CoreDataPersistence
import CoreDataPersistenceTestSupport
import QuranKit
import XCTest
@testable import LastPagePersistence

final class CoreDataLastPagePersistenceTests: XCTestCase {
    var persistence: CoreDataLastPagePersistence!
    var stack: CoreDataStack!
    var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        stack = CoreDataStack.testingStack()
        persistence = CoreDataLastPagePersistence(stack: stack)
    }

    override func tearDown() {
        super.tearDown()
        // Clean up any resources here
        CoreDataStack.removePersistentFiles()
        persistence = nil
        stack = nil
        subscriptions.removeAll()
    }

    func testAddAndRetrieveLastPages() async throws {
        // 1. Add some pages to the persistence
        let pages = [1, 2, 3]
        for pageNumber in pages {
            _ = try await persistence.add(at: page(pageNumber))
        }

        // 2. Fetch the last pages using lastPages()
        let collector = PublisherCollector(persistence.lastPages())

        // 3. Verify that the returned pages match what you expect
        XCTAssertEqual(collector.items.count, 1)
        XCTAssertEqual(collector.items.last?.map(\.page.pageNumber), [3, 2, 1])
        XCTAssertEqual(
            collector.items.last?.map(\.page.quran.pageMushaf),
            [.madani1405, .madani1405, .madani1405]
        )

        // 4. Update this page with a new number
        _ = try await persistence.update(pages: [page(1)], to: page(2))

        XCTAssertEqual(collector.items.count, 2)
        XCTAssertEqual(collector.items.last?.map(\.page.pageNumber), [2, 3])

        // 5. Update this page with the same number
        _ = try await persistence.update(pages: [page(3)], to: page(3))
        XCTAssertEqual(collector.items.last?.map(\.page.pageNumber), [3, 2])

        // 6. Add more pages.
        _ = try await persistence.add(at: page(5))
        _ = try await persistence.add(at: page(6))
        XCTAssertEqual(collector.items.last?.map(\.page.pageNumber), [6, 5, 3])
    }

    func testRetrieveAll() async throws {
        // 1. Add some pages to the persistence
        let pages = [1, 2, 3]
        for pageNumber in pages {
            _ = try await persistence.add(at: page(pageNumber))
        }

        // 2. Fetch all pages using retrieveAll()
        let lastPages = try await persistence.retrieveAll()

        // 3. Verify that the returned pages match what you expect
        XCTAssertEqual(lastPages.map(\.page.pageNumber), pages.reversed())
    }

    func testSamePageInEveryMushafIsStoredAndUpdatedIndependently() async throws {
        _ = try await persistence.add(at: page(300))
        _ = try await persistence.add(at: page(300, mushaf: .madani1440))
        _ = try await persistence.add(at: page(300, mushaf: .indoPak))

        _ = try await persistence.update(
            pages: [page(300, mushaf: .madani1440)],
            to: page(301, mushaf: .madani1440)
        )

        let lastPages = try await persistence.retrieveAll()
        XCTAssertEqual(lastPages.map(\.page.pageNumber), [301, 300, 300])
        XCTAssertEqual(lastPages.map(\.page.quran.pageMushaf), [.madani1440, .indoPak, .madani1405])
    }

    func testUpdateCollapsesEverySourcePageIntoDestination() async throws {
        _ = try await persistence.add(at: page(300))
        _ = try await persistence.add(at: page(300, mushaf: .madani1440))
        _ = try await persistence.add(at: page(300, mushaf: .indoPak))

        _ = try await persistence.update(
            pages: [
                page(300),
                page(300, mushaf: .madani1440),
                page(300, mushaf: .indoPak),
            ],
            to: page(301)
        )

        let lastPages = try await persistence.retrieveAll()
        XCTAssertEqual(lastPages.map(\.page), [page(301)])
    }

    func testLastPagesIgnoreInvalidStoredPages() async throws {
        let context = stack.viewContext
        _ = context.newLastPage(page: 605, modifiedOn: 1)
        try context.save()

        let lastPages = try await persistence.retrieveAll()

        XCTAssertTrue(lastPages.isEmpty)
    }

    private func page(
        _ pageNumber: Int,
        mushaf: QuranPageMushaf = .madani1405
    ) -> Page {
        Page(quran: mushaf.quran, pageNumber: pageNumber)!
    }
}

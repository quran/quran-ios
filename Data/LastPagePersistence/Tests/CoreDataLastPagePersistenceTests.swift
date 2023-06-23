//
//  CoreDataLastPagePersistenceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-30.
//

import AsyncUtilitiesForTesting
import Combine
import CoreDataPersistence
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
        for page in pages {
            _ = try await persistence.add(page: page)
        }

        // 2. Fetch the last pages using lastPages()
        let collector = PublisherCollector(persistence.lastPages())

        // 3. Verify that the returned pages match what you expect
        XCTAssertEqual(collector.items.count, 1)
        XCTAssertEqual(collector.items.last?.map(\.page), [3, 2, 1])

        // 4. Update this page with a new number
        _ = try await persistence.update(page: 1, toPage: 2)

        XCTAssertEqual(collector.items.count, 3)
        XCTAssertEqual(collector.items.last?.map(\.page), [2, 3])

        // 5. Update this page with the same number
        _ = try await persistence.update(page: 3, toPage: 3)
        XCTAssertEqual(collector.items.last?.map(\.page), [3, 2])

        // 6. Add more pages.
        _ = try await persistence.add(page: 5)
        _ = try await persistence.add(page: 6)
        XCTAssertEqual(collector.items.last?.map(\.page), [6, 5, 3])
    }

    func testRetrieveAll() async throws {
        // 1. Add some pages to the persistence
        let pages = [1, 2, 3]
        for page in pages {
            _ = try await persistence.add(page: page)
        }

        // 2. Fetch all pages using retrieveAll()
        let lastPages = try await persistence.retrieveAll()

        // 3. Verify that the returned pages match what you expect
        XCTAssertEqual(lastPages.map(\.page), pages.reversed())
    }
}

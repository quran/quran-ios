//
//  CoreDataLastPagePersistenceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-30.
//

import Combine
import CoreDataPersistence
@testable import LastPagePersistence
import TestUtilities
import XCTest

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

    func testAddAndRetrieveLastPages() throws {
        // 1. Add some pages to the persistence
        let pages = [1, 2, 3]
        for page in pages {
            _ = try persistence.add(page: page).wait()
        }

        // 2. Fetch the last pages using lastPages()
        let collector = PublisherCollector(persistence.lastPages())

        // 3. Verify that the returned pages match what you expect
        XCTAssertEqual(collector.items.count, 1)
        XCTAssertEqual(collector.items.last?.map(\.page), [3, 2, 1])

        // 4. Update this page with a new number
        _ = try persistence.update(page: 1, toPage: 2).wait()

        XCTAssertEqual(collector.items.count, 3)
        XCTAssertEqual(collector.items.last?.map(\.page), [2, 3])

        // 5. Update this page with the same number
        _ = try persistence.update(page: 3, toPage: 3).wait()
        XCTAssertEqual(collector.items.last?.map(\.page), [3, 2])

        // 6. Add more pages.
        _ = try persistence.add(page: 5).wait()
        _ = try persistence.add(page: 6).wait()
        XCTAssertEqual(collector.items.last?.map(\.page), [6, 5, 3])
    }

    func testRetrieveAll() throws {
        // 1. Add some pages to the persistence
        let pages = [1, 2, 3]
        for page in pages {
            _ = try persistence.add(page: page).wait()
        }

        // 2. Fetch all pages using retrieveAll()
        let lastPages = try persistence.retrieveAll().wait()

        // 3. Verify that the returned pages match what you expect
        XCTAssertEqual(lastPages.map(\.page), pages.reversed())
    }
}

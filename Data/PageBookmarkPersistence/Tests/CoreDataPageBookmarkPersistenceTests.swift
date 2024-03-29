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

        for page in pages {
            try await persistence.insertPageBookmark(page)
        }

        // 2. Fetch the page bookmarks using pageBookmarks()
        let collector = PublisherCollector(persistence.pageBookmarks())

        // 3. Verify that the returned page bookmarks match what you expect
        XCTAssertEqual(collector.items.count, 1)
        XCTAssertEqual(collector.items.last?.map(\.page), [300, 2, 1])

        // 4. Insert more
        try await persistence.insertPageBookmark(45)
        XCTAssertEqual(collector.items.last?.map(\.page), [45, 300, 2, 1])

        // 5. Remove a page bookmark
        try await persistence.removePageBookmark(2)
        XCTAssertEqual(collector.items.last?.map(\.page), [45, 300, 1])

        // 6. Remove another page bookmark
        try await persistence.removePageBookmark(45)
        XCTAssertEqual(collector.items.last?.map(\.page), [300, 1])

        // 7. Verify new collectors return same result
        let newcollector = PublisherCollector(persistence.pageBookmarks())
        XCTAssertEqual(newcollector.items.last?.map(\.page), [300, 1])
    }
}

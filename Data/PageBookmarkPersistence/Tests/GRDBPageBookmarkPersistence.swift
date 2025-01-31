//
//  GRDBPAgeBookmarkPersistence.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 01/02/2025.
//

import XCTest
import SQLitePersistence
import AsyncUtilitiesForTesting
@testable import PageBookmarkPersistence

final class GRDBPAgeBookmarkPersistenceTests: XCTestCase {
    private var testURL: URL!
    private var db: DatabaseConnection!
    private var persistence: GRDBPageBookmarkPersistence!

    override func setUp() {
        super.setUp()

        testURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        db = DatabaseConnection(url: testURL, readonly: false)
        persistence = GRDBPageBookmarkPersistence(db: db)
    }

    func testInsertAndRetrieveBookmarks() async throws {
        print(#function)
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

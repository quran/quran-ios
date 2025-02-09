//
//  GRDBPAgeBookmarkPersistence.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 01/02/2025.
//

import XCTest
import SQLitePersistence
import AsyncUtilitiesForTesting
@testable import SyncedPageBookmarkPersistence

final class GRDBSyncedPageBookmarkPersistenceTests: XCTestCase {
    private var testURL: URL!
    private var db: DatabaseConnection!
    private var persistence: GRDBSyncedPageBookmarkPersistence!

    override func setUp() {
        super.setUp()

        testURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        db = DatabaseConnection(url: testURL, readonly: false)
        persistence = GRDBSyncedPageBookmarkPersistence(db: db)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testURL)
        super.tearDown()
    }

    func testInsertAndRetrieveBookmarks() async throws {
        // 1. Insert some page bookmarks to the persistence
        let pages = [1, 2, 300]

        var cnt = 0
        // NOTE: GRDB's publishers do not guarantee that it will fire after each
        // mutation, rather, it seems to be firieing peridoically.
        let blabbity = persistence.pageBookmarks().sink { vals in
            cnt += 1
            print("#\(cnt) Received these: \(vals.map(\.page))")
        }

        for page in pages {
            try await persistence.insertPageBookmark(page)
            sleep(1)
        }

        // 2. Fetch the page bookmarks using pageBookmarks()
//        let collector = PublisherCollector(persistence.pageBookmarks())

        let publisher = persistence.pageBookmarks()

        let expectation1 = expectation(description: "Initial asserts")
        let firstAsserts = publisher.collect(1).sink { vals in
            XCTAssertEqual(vals.count, 1)
            XCTAssertEqual(Set(vals.last?.map(\.page) ?? []), Set(pages))
            expectation1.fulfill()
        }

        try await persistence.insertPageBookmark(45)

        let expectation2 = expectation(description: "Second asserts after first insert")
        let secondAsserts = publisher.collect(1).sink { vals in
            XCTAssertEqual(Set(vals.last?.map(\.page) ?? []), [45, 300, 2, 1])
            expectation2.fulfill()
        }

        try await persistence.removePageBookmark(2)

        let expectation3 = expectation(description: "Third asserts after first remove")
        let thirdAsserts = publisher.collect(1).sink { vals in
            XCTAssertEqual(Set(vals.last?.map(\.page) ?? []), [45, 300, 1])
            expectation3.fulfill()
        }

        try await persistence.removePageBookmark(45)

        let expectation4 = expectation(description: "Fourth asserts after second remove")
        let fourthAsserts = publisher.collect(4).sink { vals in
            XCTAssertEqual(Set(vals.last?.map(\.page) ?? []), [300, 1])
            expectation4.fulfill()
        }

        let newPublisher = persistence.pageBookmarks()
        let expectation5 = expectation(description: "Assertion for second publisher")
        let fifthAsserts = newPublisher.collect(1).sink { vals in
            XCTAssertEqual(Set(vals.last?.map(\.page) ?? []), [300, 1])
            expectation5.fulfill()
        }

        await fulfillment(of: [expectation1, expectation2, expectation3, expectation4, expectation5], timeout: 2)

        // 3. Verify that the returned page bookmarks match what you expect

        //        XCTAssertEqual(collector.items.count, 1)
        //        XCTAssertEqual(Set(collector.items.last?.map(\.page) ?? []), [300, 2, 1])

        // 4. Insert more
        //        try await persistence.insertPageBookmark(45)
        //        XCTAssertEqual(Set(collector.items.last?.map(\.page) ?? []), [45, 300, 2, 1])

        // 5. Remove a page bookmark
        //        try await persistence.removePageBookmark(2)
        //        XCTAssertEqual(Set(collector.items.last?.map(\.page) ?? []), [45, 300, 1])

        // 6. Remove another page bookmark
        //        try await persistence.removePageBookmark(45)
        //        XCTAssertEqual(Set(collector.items.last?.map(\.page) ?? []), [300, 1])

        // 7. Verify new collectors return same result
        //        let newcollector = PublisherCollector(persistence.pageBookmarks())
        //        XCTAssertEqual(Set(newcollector.items.last?.map(\.page) ?? []), [300, 1])
    }
}

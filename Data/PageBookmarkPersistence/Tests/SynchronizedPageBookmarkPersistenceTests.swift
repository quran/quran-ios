//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 18/02/2025.
//

import Foundation
import XCTest
import SQLitePersistence
import SyncedPageBookmarkPersistence
import PageBookmarkMutationsPersistence
@testable import PageBookmarkPersistence

final class SynchronizedPageBookmarkPersistenceTests: XCTestCase {

    private var testURL: URL!
    private var db: DatabaseConnection!
    private var syncedPersistence: SyncedPageBookmarkPersistence!
    private var localMutationsPersistence: GRDBPageBookmarkMutationsPersistence!
    private var persistence: SynchronizedPageBookmarkPersistence!

    override func setUp() {
        super.setUp()

        testURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        db = DatabaseConnection(url: testURL, readonly: false)
        syncedPersistence = GRDBSyncedPageBookmarkPersistence(directory: testURL)
        localMutationsPersistence = GRDBPageBookmarkMutationsPersistence(directory: testURL)
        persistence = SynchronizedPageBookmarkPersistence(syncedBookmarksPersistence: syncedPersistence,
                                                          bookmarkMutationsPersistence: localMutationsPersistence)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testURL)
        super.tearDown()
    }

    func testReadingOnlySynchronizedData() async throws {
        var assertExpectation: XCTestExpectation?
        var expectedPageBookmarks: [PageBookmarkPersistenceModel]?
        let cancellable = persistence.pageBookmarks()
            .sink { bookmarks in
                guard let expected = expectedPageBookmarks else { return }
                guard Set(expected.map(\.page)) == Set(bookmarks.map(\.page)) else {
                    return
                }
                XCTAssertEqual(bookmarks, expected)

                assertExpectation?.fulfill()

                assertExpectation = nil
                expectedPageBookmarks = nil
            }

        let bookmarks: [SyncedPageBookmarkPersistenceModel] = [
            .init(page: 10, remoteID: "remID:1", creationDate: .init(timeIntervalSince1970: 1_000)),
            .init(page: 22, remoteID: "remID:2", creationDate: .init(timeIntervalSince1970: 2_000)),
        ]

        let expectation1 = self.expectation(description: "Reading the first batch.")
        assertExpectation = expectation1
        expectedPageBookmarks = bookmarks.map{ PageBookmarkPersistenceModel(remoteID: $0.remoteID, page: $0.page, creationDate: $0.creationDate) }

        for bookmark in bookmarks {
            try await syncedPersistence.insertBookmark(bookmark)
        }

        await fulfillment(of: [expectation1], timeout: 1)

        // Test updates
        let added: [SyncedPageBookmarkPersistenceModel] = [
            .init(page: 35, remoteID: "remID:3", creationDate: .init(timeIntervalSince1970: 4_000)),
            .init(page: 120, remoteID: "remID:4", creationDate: .init(timeIntervalSince1970: 5_000)),
        ]

        let expectation2 = self.expectation(description: "After adding two bookmarks and removing one.")
        assertExpectation = expectation2
        expectedPageBookmarks = [
            PageBookmarkPersistenceModel(remoteID: "remID:1", page: 10, creationDate: .init(timeIntervalSince1970: 1_000)),
            PageBookmarkPersistenceModel(remoteID: "remID:3", page: 35, creationDate: .init(timeIntervalSince1970: 4_000)),
            PageBookmarkPersistenceModel(remoteID: "remID:4", page: 120, creationDate: .init(timeIntervalSince1970: 5_000)),
        ]
        for bookmark in added {
            try await syncedPersistence.insertBookmark(bookmark)
        }
        try await syncedPersistence.removeBookmark(withRemoteID: "remID:2")

        await fulfillment(of: [expectation2], timeout: 1)

        cancellable.cancel()
    }

    func testReadingOnlyBookmarkMutations() async throws {
        var assertExpectation: XCTestExpectation?
        var expectedPages: [Int]?
        let cancellable = persistence.pageBookmarks()
            .sink { bookmarks in
                guard let expected = expectedPages else { return }
                guard Set(expected) == Set(bookmarks.map(\.page)) else {
                    return
                }

                assertExpectation?.fulfill()

                assertExpectation = nil
                expectedPages = nil
            }

        let expectation1 = self.expectation(description: "Reading the first updates")
        assertExpectation = expectation1
        let addedPages: [Int] = [ 10, 12, 20 ]
        expectedPages = addedPages
        for page in addedPages {
            try await localMutationsPersistence.createBookmark(page: page)
        }
        await fulfillment(of: [expectation1], timeout: 1)

        // Will test deletions in other cases.
        cancellable.cancel()
    }
}

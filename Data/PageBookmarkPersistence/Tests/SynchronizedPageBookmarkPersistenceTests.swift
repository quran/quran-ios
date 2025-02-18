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

                print("Received bookmarks for: \(bookmarks.map(\.page)). Expected: \(expectedPageBookmarks?.map(\.page) ?? [])")
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

        let expectation1 = self.expectation(description: "")
        assertExpectation = expectation1
        expectedPageBookmarks = bookmarks.map{ PageBookmarkPersistenceModel(remoteID: $0.remoteID, page: $0.page, creationDate: $0.creationDate) }

        for bookmark in bookmarks {
            try await syncedPersistence.insertBookmark(bookmark)
        }

        await fulfillment(of: [expectation1], timeout: 2)


        cancellable.cancel()
    }
}

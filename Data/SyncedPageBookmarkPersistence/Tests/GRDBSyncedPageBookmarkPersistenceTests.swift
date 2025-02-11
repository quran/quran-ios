//
//  GRDBSyncedPageBookmarkPersistenceTests.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 01/02/2025.
//

import AsyncUtilitiesForTesting
import SQLitePersistence
import XCTest
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

    func testInsertion() async throws {
        let pages = [1, 2, 300]

        let expectedBookmarkedPages = [1, 2, 300]

        let exp = expectation(description: "Expected to send the expected bookmarks")
        let cancellable = try persistence.pageBookmarksPublisher()
            .sink { bookmarks in
                let pages = bookmarks.map(\.page)
                guard Set(pages) == Set(expectedBookmarkedPages) else {
                    return
                }
                exp.fulfill()
            }

        for page in pages {
            try await persistence.insertBookmark(SyncedPageBookmarkPersistenceModel(page: page))
        }
        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
    }

    func testDeletion() async throws {
        let pageNos = [1, 2, 300]
        let pages = pageNos.map(SyncedPageBookmarkPersistenceModel.init(page:))
        for page in pages {
            try await persistence.insertBookmark(page)
        }

        let expectedPageNumbers = [1, 300]
        let exp = expectation(description: "Expected to send the expected bookmarks without the deleted one")
        let cancellable = try persistence.pageBookmarksPublisher()
            .sink { bookmarks in
                let pages = bookmarks.map(\.page)
                guard Set(pages) == Set(expectedPageNumbers) else {
                    return
                }
                exp.fulfill()
            }

        try await persistence.removeBookmark(withRemoteID: pages[1].remoteID)

        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
    }
}

private extension SyncedPageBookmarkPersistenceModel {
    init(page: Int) {
        self.init(page: page, remoteID: UUID().uuidString, creationDate: .distantPast)
    }
}

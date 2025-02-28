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
import MutatedPageBookmarkPersistence
import AsyncUtilitiesForTesting
@testable import PageBookmarkPersistence

final class SynchronizablePageBookmarkPersistenceTests: XCTestCase {

    private var testURL: URL!
    private var db: DatabaseConnection!
    private var syncedPersistence: SyncedPageBookmarkPersistence!
    private var localMutationsPersistence: GRDBMutatedPageBookmarkPersistence!
    private var persistence: SynchronizablePageBookmarkPersistence!

    override func setUp() {
        super.setUp()

        testURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        db = DatabaseConnection(url: testURL, readonly: false)
        syncedPersistence = GRDBSyncedPageBookmarkPersistence(directory: testURL)
        localMutationsPersistence = GRDBMutatedPageBookmarkPersistence(directory: testURL)
        persistence = SynchronizablePageBookmarkPersistence(syncedBookmarksPersistence: syncedPersistence,
                                                          bookmarkMutationsPersistence: localMutationsPersistence)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testURL)
        super.tearDown()
    }

    func testMergingSyncedAndMutatedBookmarks() async throws {
        var assertexpectation: XCTestExpectation?
        var expecteBookmarks: [PageBookmarkPersistenceModel]?
        let cancellable = persistence.pageBookmarks()
            .sink { bookmarks in
                guard let expected = expecteBookmarks else { return }
                guard Set(expected.map(\.page)) == Set(bookmarks.map(\.page)) else {
                    return
                }
                assertexpectation?.fulfill()
                assertexpectation = nil
                expecteBookmarks = nil
            }

        let expectation1 = self.expectation(description: "Merging the initial uncolliding bookmarks")
        assertexpectation = expectation1
        expecteBookmarks = [
            .init(remoteID: "remID:1", page: 10, creationDate: .init(timeIntervalSince1970: 1_000)),
            .init(remoteID: "remID:2", page: 15, creationDate: .init(timeIntervalSince1970: 2_000)),
            .init(page: 23, creationDate: Date()),
            .init(page: 25, creationDate: Date()),
            .init(page: 100, creationDate: Date()),
        ]

        let syncedBookmarks: [SyncedPageBookmarkPersistenceModel] = [
            .init(page: 10, remoteID: "remID:1", creationDate: .init(timeIntervalSince1970: 1_000)),
            .init(page: 15, remoteID: "remID:2", creationDate: .init(timeIntervalSince1970: 2_000)),
        ]
        let newPages: [Int] = [ 23, 25, 100 ]
        for bookmark in syncedBookmarks {
            try await syncedPersistence.insertBookmark(bookmark)
        }
        for page in newPages {
            try await localMutationsPersistence.createBookmark(page: page)
        }
        await fulfillment(of: [expectation1])

        let expectation2 = self.expectation(description: "Merging: one synced bookmark removed")
        assertexpectation = expectation2
        expecteBookmarks = [
            .init(remoteID: "remID:2", page: 15, creationDate: .init(timeIntervalSince1970: 1_000)),
            .init(page: 23, creationDate: Date()),
            .init(page: 25, creationDate: Date()),
            .init(page: 100, creationDate: Date()),
        ]
        try await localMutationsPersistence.removeBookmark(page: 10, remoteID: "remID:1")

        await fulfillment(of: [expectation2], timeout: 1)

        let expectation3 = self.expectation(description: "Merging: Locally adding the removed bookmark")
        assertexpectation = expectation3
        expecteBookmarks = [
            .init(remoteID: "remID:2", page: 15, creationDate: .init(timeIntervalSince1970: 1_000)),
            .init(page: 23, creationDate: Date()),
            .init(page: 25, creationDate: Date()),
            .init(page: 100, creationDate: Date()),
            .init(page: 10, creationDate: Date()),
        ]
        try await localMutationsPersistence.createBookmark(page: 10)
        
        await fulfillment(of: [expectation3], timeout: 1)


        cancellable.cancel()
    }

    func testMutationsPublished() async throws {
        // Initialize with syncrhonized data.
        let syncedBookmarks: [SyncedPageBookmarkPersistenceModel] = [
            .init(page: 10, remoteID: "remID:1", creationDate: .init(timeIntervalSince1970: 1_000)),
            .init(page: 22, remoteID: "remID:2", creationDate: .init(timeIntervalSince1970: 3_000)),
            .init(page: 33, remoteID: "remID:3", creationDate: .init(timeIntervalSince1970: 10_000)),
        ]
        for bookmark in syncedBookmarks {
            try await syncedPersistence.insertBookmark(bookmark)
        }

        // Insert and delete some records locally
        try await localMutationsPersistence.createBookmark(page: 40)
        try await localMutationsPersistence.removeBookmark(page: 22, remoteID: "remID:2")

        var assertexpectation: XCTestExpectation?
        var expecteBookmarkedPages: [Int]?
        let cancellable = persistence.pageBookmarks()
            .sink { bookmarks in
                print("Received bookmarks on: \(bookmarks.map(\.page))")
                guard let expected = expecteBookmarkedPages else { return }
                guard Set(expected) == Set(bookmarks.map(\.page)) else {
                    return
                }
                assertexpectation?.fulfill()
                assertexpectation = nil
                expecteBookmarkedPages = nil
            }

        // Insert a new one
        let expectation1 = self.expectation(description: "After creating a new bookmark")
        assertexpectation = expectation1
        expecteBookmarkedPages = [10, 33, 40, 230]

        try await persistence.insertPageBookmark(230)

        await fulfillment(of: [expectation1], timeout: 1)

        // Insert some and remove some
        let expectation2 = self.expectation(description: "After creating some and removing some")
        assertexpectation = expectation2
        expecteBookmarkedPages = [22, 33, 40, 100, 230]

        try await persistence.removePageBookmark(10)
        try await persistence.insertPageBookmark(100)
        try await persistence.insertPageBookmark(22) // Add it again

        await fulfillment(of: [expectation2], timeout: 2)


        cancellable.cancel()
    }

    func testDeletionsSideEffects() async throws {
        // Initialize with syncrhonized data.
        let syncedBookmarks: [SyncedPageBookmarkPersistenceModel] = [
            .init(page: 10, remoteID: "remID:1", creationDate: .init(timeIntervalSince1970: 1_000)),
            .init(page: 22, remoteID: "remID:2", creationDate: .init(timeIntervalSince1970: 3_000)),
        ]
        for bookmark in syncedBookmarks {
            try await syncedPersistence.insertBookmark(bookmark)
        }

        // Delete
        try await persistence.removePageBookmark(22)

        // Assert
        try await AsyncAssertEqual(try await localMutationsPersistence.bookmarks().first?.page,
                                   22,
                                   "Expected to have a record for page 22 in the local mutations persistence")
        try await AsyncAssertEqual(try await localMutationsPersistence.bookmarks().first?.remoteID,
                                   "remID:2",
                                   "Expected to have a the correct remote ID")
        try await AsyncAssertEqual(try await localMutationsPersistence.bookmarks().first?.mutation,
                                   .deleted,
                                   "Expected to have the correct mutation event.")
        try await AsyncAssertEqual(try await syncedPersistence.bookmark(page: 22) != nil,
                                   true,
                                   "Expected not to be removed from the synced table")

        //
        // Preparses some local mutations
        try await localMutationsPersistence.createBookmark(page: 301)

        // Delete
        try await persistence.removePageBookmark(301)

        // Assert
        try await AsyncAssertEqual(try await localMutationsPersistence.bookmarks().map(\.page), [22])
    }

    func testCreationsSideEffects() async throws {
        // Initialize with syncrhonized data.
        let syncedBookmarks: [SyncedPageBookmarkPersistenceModel] = [
            .init(page: 10, remoteID: "remID:1", creationDate: .init(timeIntervalSince1970: 1_000)),
        ]
        for bookmark in syncedBookmarks {
            try await syncedPersistence.insertBookmark(bookmark)
        }

        // Insert
        try await persistence.insertPageBookmark(123)

        // Assert
        try await AsyncAssertEqual(try await localMutationsPersistence.bookmarks().first?.page,
                                   123,
                                   "Expected to have a record for page 123 in the local mutations persistence")
        try await AsyncAssertEqual(try await localMutationsPersistence.bookmarks().first?.remoteID,
                                   nil,
                                   "Expected to have a nil remote ID.")
        try await AsyncAssertEqual(try await localMutationsPersistence.bookmarks().first?.mutation,
                                   .created,
                                   "Expected to have the correct mutation event.")
        try await AsyncAssertEqual(try await syncedPersistence.bookmark(page: 123) == nil,
                                   true,
                                   "Expected not to be added in the synced table")

        // Attempt duplicates
        await AsyncAssertThrows(try await persistence.insertPageBookmark(10), nil,
                                "Should fail if tried to duplicate")
        await AsyncAssertThrows(try await persistence.insertPageBookmark(123), nil,
                                "Should fail if tried to duplicate")
    }
}

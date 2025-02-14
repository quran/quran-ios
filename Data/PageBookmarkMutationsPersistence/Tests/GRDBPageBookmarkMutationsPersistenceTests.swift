//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 11/02/2025.
//

import Foundation
import SQLitePersistence
import AsyncUtilitiesForTesting
import XCTest

@testable import PageBookmarkMutationsPersistence

final class GRDBPageBookmarkMutationsPersistenceTests: XCTestCase {
    private var testURL: URL!
    private var db: DatabaseConnection!
    private var persistence: GRDBPageBookmarkMutationsPersistence!

    override func setUp() {
        super.setUp()

        testURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        db = DatabaseConnection(url: testURL, readonly: false)
        persistence = GRDBPageBookmarkMutationsPersistence(db: db)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testURL)
        super.tearDown()
    }

    func testCreation() async throws {
        try await persistence.createBookmark(page: 10)
        try await persistence.createBookmark(page: 20)

        await AsyncAssertThrows(
            try await persistence.createBookmark(page: 10),
            nil,
            "Should throw if tried to duplicate a bookmark on a page."
        )

        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.page), [10, 20])
        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.deleted), [false, false])

        let date = Date()
        try await AsyncAssertEqual(
            try await persistence.bookmarks()
                .map(\.modificationDate)
                .map(date.timeIntervalSince).map{ $0 < 5 }, // enough to judge for recency, while giving enough leeway for exeuction latency.
            [true, true],
            "Expected mofication dates to be recent.")
    }

    func testRemovingSyncedBookmark() async throws {
        try await persistence.removeBookmark(.init(remoteID: "remID:abc",
                                                   page: 12,
                                                   modificationDate: .distantPast,
                                                   deleted: false))

        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.page), [12])
        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.deleted), [true])
        try await AsyncAssertEqual(
            try await persistence.bookmarks().first
                .map{ Date().timeIntervalSince($0.modificationDate) < 5 },
            true,
            "Modification date should be adjusted")
    }

    func testRemovingUnsyncedBookmark() async throws {
        try await persistence.createBookmark(page: 12)
        try await persistence.removeBookmark(.init(remoteID: nil,
                                                   page: 12,
                                                   modificationDate: .distantPast,
                                                   deleted: false))

        try await AsyncAssertEqual(try await persistence.bookmarks().count, 0)
    }

    func testRecreatingDeletedSyncedBookmark() async throws {
        // Synced
        try await persistence.removeBookmark(.init(remoteID: "remID:abc",
                                                   page: 13,
                                                   modificationDate: .distantPast,
                                                   deleted: false))
        try await persistence.createBookmark(page: 13)

        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.page), [13, 13])
        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.remoteID),
                                   ["remID:abc", nil],
                                   "Expected to have two records: one for the synced bookmark, and a new unsynced one.")
        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.deleted),
                                   [true, false],
                                   "The synced record should be marked for deletion. The unsynced one is created.")

        let date = Date()
        try await AsyncAssertEqual(
            try await persistence.bookmarks()
                .map(\.modificationDate)
                .map{ date.timeIntervalSince($0) }
                .map{ $0 < 5}, [true, true],
            "The modification dates should be recent.")
    }

    func testRecreatingDeletedUnsyncedBookmark() async throws {
        try await persistence.createBookmark(page: 22)
        try await persistence.removeBookmark(.init(remoteID: nil,
                                                   page: 22,
                                                   modificationDate: .distantPast,
                                                   deleted: false))

        try await persistence.createBookmark(page: 22)

        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.page), [22])
        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.deleted), [false])
    }

    func testClearingAll() async throws {
        try await persistence.createBookmark(page: 10)
        try await persistence.createBookmark(page: 22)
        try await persistence.removeBookmark(.init(remoteID: "remID:12dc",
                                                   page: 34,
                                                   modificationDate: .distantPast,
                                                   deleted: false))
        try await persistence.createBookmark(page: 200)

        try await persistence.clear()

        try await AsyncAssertEqual(try await persistence.bookmarks().count, 0)
    }

    func testPublisher() async throws {
        var assertionExp: XCTestExpectation?
        var expectedBookmarks: [MutatedPageBookmarkModel]?
        let cancellable = try persistence.bookmarksPublisher().sink { bookmarks in
            guard let expected = expectedBookmarks else {
                return
            }
            if Set(bookmarks.map(\.page)) == Set(expected.map(\.page)) {
                assertionExp?.fulfill()
                assertionExp = nil
                expectedBookmarks = nil
            }
        }

        let exp1 = expectation(description: "After two creations and one deletion. Expecting 3")
        assertionExp = exp1
        expectedBookmarks = [
            .init(remoteID: nil, page: 100, modificationDate: .distantPast, deleted: false),
            .init(remoteID: nil, page: 102, modificationDate: .distantPast, deleted: false),
            .init(remoteID: "remID:abd34", page: 35, modificationDate: .distantPast, deleted: true)
        ]
        try await persistence.createBookmark(page: 100)
        try await persistence.createBookmark(page: 102)
        try await persistence.removeBookmark(.init(remoteID: "remID:abd34",
                                                   page: 35,
                                                   modificationDate: .distantPast,
                                                   deleted: false))
        await fulfillment(of: [exp1], timeout: 1)

        let exp2 = expectation(description: "")
        assertionExp = exp2
        expectedBookmarks = [
            .init(remoteID: nil, page: 100, modificationDate: .distantPast, deleted: false),
            .init(remoteID: "remID:abd34", page: 35, modificationDate: .distantPast, deleted: true),
            .init(remoteID: nil, page: 201, modificationDate: .distantPast, deleted: false),
        ]
        try await persistence.createBookmark(page: 201)
        try await persistence.removeBookmark(.init(remoteID: nil, page: 102, modificationDate: .distantPast, deleted: false))

        await fulfillment(of: [exp2], timeout: 1)

        cancellable.cancel()
    }
}

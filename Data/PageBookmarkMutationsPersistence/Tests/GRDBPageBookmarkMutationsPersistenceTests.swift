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

    func testCreationAndRemoval() async throws {
        try await persistence.createBookmark(page: 10)
        try await persistence.createBookmark(page: 20)

        await AsyncAssertThrows(try await persistence.createBookmark(page: 10), nil)

        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.page), [10, 20])
        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.deleted), [false, false])
    }

    func testRemovingSyncedBookmark() async throws {
        try await persistence.removeBookmark(.init(remoteID: "remID:abc",
                                                   page: 12,
                                                   modificationDate: .distantPast,
                                                   deleted: false))

        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.page), [12])
        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.deleted), [true])
    }

    func testRemovingUnsyncedBookmark() async throws {
        try await persistence.createBookmark(page: 12)
        try await persistence.removeBookmark(.init(remoteID: nil,
                                                   page: 12,
                                                   modificationDate: .distantPast,
                                                   deleted: false))
        
        try await AsyncAssertEqual(try await persistence.bookmarks().count, 0)
    }

    func testRecreatingDeletedBookmark() async throws {
        // Synced
        try await persistence.removeBookmark(.init(remoteID: "remID:abc",
                                                   page: 13,
                                                   modificationDate: .distantPast,
                                                   deleted: false))
        try await persistence.createBookmark(page: 13)

        try await AsyncAssertEqual(try await persistence.bookmarks().count, 0)

        // Unsynced
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
}

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
        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.page), [10, 20])
        try await AsyncAssertEqual(try await persistence.bookmarks().map(\.deleted), [false, false])
    }
}

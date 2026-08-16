//
//  CoreDataPersistentHistoryTokenStoreTests.swift
//

import Foundation
import XCTest
@testable import CoreDataPersistence

final class CoreDataPersistentHistoryTokenStoreTests: XCTestCase {
    func test_load_removesUnreadableToken() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreDataPersistentHistoryTokenStoreTests-\(UUID().uuidString)")
        let fileURL = directoryURL.appendingPathComponent("token.data")
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try Data("unreadable token".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let sut = CoreDataPersistentHistoryTokenStore(fileURL: fileURL)

        XCTAssertNil(sut.load())
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }
}

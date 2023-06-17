//
//  DatabaseConnectionTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-27.
//

import AsyncUtilitiesForTesting
import GRDB
import XCTest
@testable import SQLitePersistence

class DatabaseConnectionTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        // Create a temporary file for the test database.
        testURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testURL)
        super.tearDown()
    }

    func test_creation() throws {
        let connection = DatabaseConnection(url: testURL)
        XCTAssertNotNil(connection)
        // Initially database file is not created.
        XCTAssertFalse(testURL.isReachable)
    }

    func test_readAndWrite() async throws {
        let connection = DatabaseConnection(url: testURL)
        try await connection.insertNames()

        XCTAssertTrue(testURL.isReachable)

        let names = try await connection.readNames()
        XCTAssertEqual(names, ["Alice"])
    }

    func test_sharing() async throws {
        let connection1 = DatabaseConnection(url: testURL)
        let connection2 = DatabaseConnection(url: testURL)
        try await connection1.insertNames()
        let names = try await connection2.readNames()
        XCTAssertEqual(names, ["Alice"])
    }

    func test_release() throws {
        var connection: DatabaseConnection? = DatabaseConnection(url: testURL)
        weak var weakConnection = connection
        connection = nil // should call deinit
        XCTAssertNil(weakConnection)
    }

    func test_corruption() async throws {
        // Simulate a database corruption manually.
        try "corrupted data".write(to: testURL, atomically: true, encoding: .utf8)

        let connection = DatabaseConnection(url: testURL)
        await AsyncAssertThrows(try await {
            _ = try await connection.readNames()
        }(), nil)

        // Database should be deleted because the error is SQLITE_NOTADB.
        XCTAssertFalse(testURL.isReachable)
    }

    // MARK: Private

    private var testURL: URL!
}

private extension DatabaseConnection {
    func insertNames() async throws {
        try await write { db in
            try db.create(table: "test") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text)
            }
            try db.execute(sql: "INSERT INTO test (name) VALUES (?)", arguments: ["Alice"])
        }
    }

    func readNames() async throws -> [String] {
        try await read { db in
            try String.fetchAll(db, sql: "SELECT name FROM test")
        }
    }
}

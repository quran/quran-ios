//
//  DatabaseConnectionTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-27.
//

import AsyncUtilitiesForTesting
import Combine
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
        let connection = DatabaseConnection(url: testURL, readonly: false)
        try await connection.insertNames()

        XCTAssertTrue(testURL.isReachable)

        let names = try await connection.readNames()
        XCTAssertEqual(names, ["Alice"])
    }

    func test_readPublisher() async throws {
        // Since we can't guarantee a defined sequence of intermediate states, the test
        // here attempts to perform a series of changes in a way that would eventually
        // deliver a specifc set of values.
        // Adding some latency is key, as it allows SQLite to commit changes to the desk.
        let connection = DatabaseConnection(url: testURL, readonly: false)
        try await connection.createTable()
        let publisher = try connection.namesPublisher()
            .catch { _ in Empty<[String], Never>() }
            .eraseToAnyPublisher()

        var assertExpectation: XCTestExpectation?
        var expectedNames: [String]?
        let cancellable = publisher.sink { names in
            guard let expected = expectedNames else { return }

            if Set(expected) == Set(names) {
                assertExpectation?.fulfill()
                assertExpectation = nil
                expectedNames = nil
            }
        }

        expectedNames = ["Alice"]
        let expectation1 = expectation(description: "Expected to deliver the first batch of inserted names")
        assertExpectation = expectation1
        try await connection.insert(name: "Alice")
        await fulfillment(of: [expectation1], timeout: 2)

        // Add more
        expectedNames = ["Alice", "Bob", "Derek"]
        let expectation2 = expectation(description: "Expected to deliver the second batch of names")
        assertExpectation = expectation2
        try await connection.insert(name: "Bob")
        try await connection.insert(name: "Derek")
        await fulfillment(of: [expectation2], timeout: 2)

        // Remove one
        expectedNames = ["Alice", "Derek"]
        let expectation3 = expectation(description: "Expected to deliver the third batch of names")
        assertExpectation = expectation3
        try await connection.remove(name: "Bob")
        await fulfillment(of: [expectation3], timeout: 2)

        cancellable.cancel()
    }

    func test_sharing() async throws {
        let connection1 = DatabaseConnection(url: testURL, readonly: false)
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
    func createTable() async throws {
        try await write { db in
            try db.create(table: "test") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text)
            }
        }
    }

    func insertNames() async throws {
        try await write { db in
            try db.create(table: "test") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text)
            }
            try db.execute(sql: "INSERT INTO test (name) VALUES (?)", arguments: ["Alice"])
        }
    }

    func insert(name: String) async throws {
        try await write { db in
            try db.execute(sql: "INSERT INTO test (name) VALUES (?)", arguments: StatementArguments([name]))
        }
    }

    func remove(name: String) async throws {
        try await write { db in
            try db.execute(sql: "DELETE FROM test WHERE name = ?", arguments: [name])
        }
    }

    func namesPublisher() throws -> AnyPublisher<[String], Error> {
        try readPublisher { db in
            try String.fetchAll(db, sql: "SELECT name FROM test")
        }
    }

    func readNames() async throws -> [String] {
        try await read { db in
            try String.fetchAll(db, sql: "SELECT name FROM test")
        }
    }
}

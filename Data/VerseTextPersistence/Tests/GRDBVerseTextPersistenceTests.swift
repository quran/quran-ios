import GRDB
import QuranKit
import XCTest
@testable import VerseTextPersistence

final class GRDBVerseTextPersistenceTests: XCTestCase {
    func testTranslationSearchSkipsIntegerVerseReferences() async throws {
        let databaseURL = try makeTranslationDatabase(text: Int64(3666))
        defer { try? FileManager.default.removeItem(at: databaseURL) }

        let sut = GRDBTranslationVerseTextPersistence(fileURL: databaseURL)
        let results = try await sut.search(for: "3666", quran: .hafsMadani1405)

        XCTAssertTrue(results.isEmpty)
    }

    func testTranslationSearchSkipsNumericStringVerseReferences() async throws {
        let databaseURL = try makeTranslationDatabase(text: "3666")
        defer { try? FileManager.default.removeItem(at: databaseURL) }

        let sut = GRDBTranslationVerseTextPersistence(fileURL: databaseURL)
        let results = try await sut.search(for: "3666", quran: .hafsMadani1405)

        XCTAssertTrue(results.isEmpty)
    }

    func testSearchSkipsInvalidVerseCoordinatesAndKeepsValidRows() async throws {
        let databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        defer { try? FileManager.default.removeItem(at: databaseURL) }

        let database = try DatabaseQueue(path: databaseURL.path)
        try await database.write { db in
            try db.execute(sql: """
            CREATE VIRTUAL TABLE verses USING fts3(sura INTEGER, ayah INTEGER, text TEXT);
            INSERT INTO verses(sura, ayah, text) VALUES
                (1, 1, 'needle valid'),
                (1, 999, 'needle invalid');
            """)
        }

        let sut = GRDBTranslationVerseTextPersistence(fileURL: databaseURL)
        let results = try await sut.search(for: "needle", quran: .hafsMadani1405)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.verse, Quran.hafsMadani1405.firstVerse)
        XCTAssertEqual(results.first?.text, "needle valid")
    }

    private func makeTranslationDatabase(text: some DatabaseValueConvertible) throws -> URL {
        let databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        let database = try DatabaseQueue(path: databaseURL.path)
        try database.write { db in
            try db.execute(sql: """
            CREATE VIRTUAL TABLE verses USING fts3(sura INTEGER, ayah INTEGER, text TEXT);
            """)
            try db.execute(
                sql: "INSERT INTO verses(sura, ayah, text) VALUES (35, 5, ?)",
                arguments: [text]
            )
        }
        return databaseURL
    }
}

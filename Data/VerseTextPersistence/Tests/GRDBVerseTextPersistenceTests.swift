import GRDB
import QuranKit
import XCTest
@testable import VerseTextPersistence

final class GRDBVerseTextPersistenceTests: XCTestCase {
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
}

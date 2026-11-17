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

    func testTranslationTextDecodesHTMLEntities() async throws {
        let databaseURL = try makeTranslationDatabase(
            text: "He said: &quot;{ABC}&quot; it&#39;s &#x2014; [[Sam, Ham, &amp; Yafis]] &lt;FG&gt;"
        )
        defer { try? FileManager.default.removeItem(at: databaseURL) }

        let sut = GRDBTranslationVerseTextPersistence(fileURL: databaseURL)
        let texts = try await sut.textForVerses([verse])

        XCTAssertEqual(texts, [verse: .string("He said: \"{ABC}\" it's \u{2014} [[Sam, Ham, & Yafis]] <FG>")])
    }

    func testTranslationTextKeepsAmpersandsThatAreNotHTMLEntities() async throws {
        let storedText = "Koran & Soennah &unknown; &amp"

        let text = try await translationText(storedText: storedText)

        XCTAssertEqual(text, .string(storedText))
    }

    func testTranslationTextKeepsNumericReferencesThatAreNotUnicodeScalars() async throws {
        let storedText = "surrogate &#xD800; out of range &#1114112;"

        let text = try await translationText(storedText: storedText)

        XCTAssertEqual(text, .string(storedText))
    }

    func testTranslationTextKeepsControlCharacterReferences() async throws {
        let storedText = "null &#0; unit &#x1F; delete &#127; private &#146;"

        let text = try await translationText(storedText: storedText)

        XCTAssertEqual(text, .string(storedText))
    }

    func testTranslationTextDecodesEntitiesInASinglePass() async throws {
        let text = try await translationText(storedText: "&amp;quot;")

        XCTAssertEqual(text, .string("&quot;"))
    }

    func testTranslationTextDecodesTabAndLineFeedReferences() async throws {
        let text = try await translationText(storedText: "tab&#9;line&#10;end")

        XCTAssertEqual(text, .string("tab\tline\nend"))
    }

    func testTranslationSearchReturnsDecodedText() async throws {
        let databaseURL = try makeTranslationDatabase(text: "dicendo &quot;perdono&quot;")
        defer { try? FileManager.default.removeItem(at: databaseURL) }

        let sut = GRDBTranslationVerseTextPersistence(fileURL: databaseURL)
        let results = try await sut.search(for: "perdono", quran: .hafsMadani1405)

        XCTAssertEqual(results.map(\.verse), [verse])
        XCTAssertEqual(results.map(\.text), ["dicendo \"perdono\""])
    }

    func testTranslationAutocompleteReturnsDecodedText() async throws {
        let databaseURL = try makeTranslationDatabase(text: "dicendo &quot;perdono&quot;")
        defer { try? FileManager.default.removeItem(at: databaseURL) }

        let sut = GRDBTranslationVerseTextPersistence(fileURL: databaseURL)
        let results = try await sut.autocomplete(term: "perd")

        XCTAssertEqual(results, ["dicendo \"perdono\""])
    }

    private let verse = AyahNumber(quran: .hafsMadani1405, sura: 35, ayah: 5)!

    private func translationText(storedText: String) async throws -> TranslationTextPersistenceModel {
        let databaseURL = try makeTranslationDatabase(text: storedText)
        defer { try? FileManager.default.removeItem(at: databaseURL) }

        let sut = GRDBTranslationVerseTextPersistence(fileURL: databaseURL)
        return try await sut.textForVerse(verse)
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

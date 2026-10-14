#if QURAN_SYNC
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import AnnotationsService

final class MobileSyncNoteServiceTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private var service: MobileSyncNoteService!

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        service = MobileSyncNoteService(quranDataService: database.quranDataService)
    }

    override func tearDown() async throws {
        try await database.reset()
        service = nil
        try await super.tearDown()
    }

    func test_createNote_persistsBodyAndRange() async throws {
        try await service.createNote(body: "Remember this", startAyah: ayah(1), endAyah: ayah(2))

        let note = try await storedNote()
        XCTAssertEqual(note.text, "Remember this")
        XCTAssertEqual(note.startAyah, ayah(1))
        XCTAssertEqual(note.endAyah, ayah(2))
    }

    func test_updateNote_changesBodyAndKeepsRange() async throws {
        try await service.createNote(body: "Original", startAyah: ayah(1), endAyah: ayah(2))
        let original = try await storedNote()

        try await service.updateNote(original, body: "Updated")

        let updated = try await storedNote()
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.text, "Updated")
        XCTAssertEqual(updated.startAyah, ayah(1))
        XCTAssertEqual(updated.endAyah, ayah(2))
    }

    func test_removeNote_deletesPersistedNote() async throws {
        try await service.createNote(body: "Delete me", startAyah: ayah(1), endAyah: ayah(1))
        let note = try await storedNote()

        try await service.removeNote(note)

        let deleted = expectation(description: "The database publishes the deletion")
        let observation = Task {
            for try await notes in service.notesSequence(quran: .hafsMadani1405) where notes.isEmpty {
                deleted.fulfill()
                return
            }
        }
        await fulfillment(of: [deleted], timeout: 2)
        observation.cancel()
    }

    func test_createNote_throwsTextLengthLimitErrorForShortBody() async throws {
        await assertThrows(TextLengthLimitError(field: .noteBody, bound: .tooShort, limit: 6)) {
            try await service.createNote(body: " ab ", startAyah: ayah(1), endAyah: ayah(1))
        }

        let notes = try await storedNotes()
        XCTAssertTrue(notes.isEmpty)
    }

    func test_createNote_measuresBodyAsTheServerEscapesIt() async {
        // 2,001 ampersands are 10,005 characters once escaped as `&amp;`.
        await assertThrows(TextLengthLimitError(field: .noteBody, bound: .tooLong, limit: 10000)) {
            try await service.createNote(body: String(repeating: "&", count: 2001), startAyah: ayah(1), endAyah: ayah(1))
        }
    }

    func test_updateNote_throwsTextLengthLimitErrorAndKeepsStoredBody() async throws {
        try await service.createNote(body: "Original", startAyah: ayah(1), endAyah: ayah(1))
        let original = try await storedNote()

        await assertThrows(TextLengthLimitError(field: .noteBody, bound: .tooLong, limit: 10000)) {
            try await service.updateNote(original, body: String(repeating: "a", count: 10001))
        }

        let stored = try await storedNote()
        XCTAssertEqual(stored.text, "Original")
    }

    private func assertThrows(
        _ expected: TextLengthLimitError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? TextLengthLimitError, expected, file: file, line: line)
        }
    }

    private func storedNotes() async throws -> [QuranAnnotations.Note] {
        var iterator = service.notesSequence(quran: .hafsMadani1405).makeAsyncIterator()
        return try await iterator.next() ?? []
    }

    private func storedNote() async throws -> QuranAnnotations.Note {
        var iterator = service.notesSequence(quran: .hafsMadani1405).makeAsyncIterator()
        let notes = try await iterator.next()
        return try XCTUnwrap(notes?.first)
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: number)!
    }
}
#endif

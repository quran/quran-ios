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

    func test_updateNote_persistsBodyAndRange() async throws {
        try await service.createNote(body: "Original", startAyah: ayah(1), endAyah: ayah(1))
        let original = try await storedNote()

        try await service.updateNote(original, body: "Updated", startAyah: ayah(2), endAyah: ayah(3))

        let updated = try await storedNote()
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.text, "Updated")
        XCTAssertEqual(updated.startAyah, ayah(2))
        XCTAssertEqual(updated.endAyah, ayah(3))
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

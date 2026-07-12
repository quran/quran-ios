#if QURAN_SYNC
import AnnotationsService
import Combine
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import QuranViewFeature

@MainActor
final class QuranNotesObserverTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private var noteService: MobileSyncNoteService!

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        noteService = MobileSyncNoteService(quranDataService: database.quranDataService)
    }

    override func tearDown() async throws {
        try await database.reset()
        noteService = nil
        try await super.tearDown()
    }

    func test_start_observesPersistedNotesFromMobileSyncDatabase() async throws {
        try await noteService.createNote(body: "Stored note", startAyah: ayah(1), endAyah: ayah(2))
        let sut = QuranNotesObserver(noteService: noteService, quran: .hafsMadani1405)
        let observed = expectation(description: "Observes persisted note")
        let observation = sut.$notes.sink { notes in
            if notes.map(\.text) == ["Stored note"] {
                observed.fulfill()
            }
        }

        sut.start()
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertEqual(sut.notes(interacting: [ayah(2)]).map(\.text), ["Stored note"])
        observation.cancel()
        withExtendedLifetime(sut) {}
    }

    func test_remove_deletesNoteFromMobileSyncDatabase() async throws {
        try await noteService.createNote(body: "Delete me", startAyah: ayah(1), endAyah: ayah(1))
        let notes = try await storedNotes()
        let note = try XCTUnwrap(notes.first)
        let sut = QuranNotesObserver(noteService: noteService, quran: .hafsMadani1405)

        try await sut.remove(note)

        let remainingNotes = try await storedNotes()
        XCTAssertTrue(remainingNotes.isEmpty)
    }

    private func storedNotes() async throws -> [Note] {
        var iterator = noteService.notesSequence(quran: .hafsMadani1405).makeAsyncIterator()
        return try await iterator.next() ?? []
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: number)!
    }
}
#endif

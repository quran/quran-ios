#if QURAN_SYNC
import AnnotationsService
import Combine
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import NotesFeature

@MainActor
final class AyahNotesViewModelTests: XCTestCase {
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

    func test_start_observesEveryNoteIntersectingTheSelectedAyahs() async throws {
        try await noteService.createNote(body: "First", startAyah: ayah(1), endAyah: ayah(2))
        try await noteService.createNote(body: "Second", startAyah: ayah(2), endAyah: ayah(3))
        try await noteService.createNote(body: "Unrelated", startAyah: ayah(4), endAyah: ayah(4))
        let sut = makeSUT(verses: [ayah(2)])
        let observed = expectation(description: "Observes intersecting notes")
        var didFulfill = false
        let observation = sut.$notes.sink { notes in
            guard !didFulfill, Set(notes.map(\.text)) == ["First", "Second"] else {
                return
            }
            didFulfill = true
            observed.fulfill()
        }

        let task = Task { await sut.start() }
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertEqual(Set(sut.notes.map(\.text)), ["First", "Second"])
        task.cancel()
        observation.cancel()
    }

    func test_deleteNote_removesOnlyTheSelectedNote() async throws {
        try await noteService.createNote(body: "Keep", startAyah: ayah(1), endAyah: ayah(1))
        try await noteService.createNote(body: "Delete", startAyah: ayah(1), endAyah: ayah(1))
        let notes = try await storedNotes()
        let noteToDelete = try XCTUnwrap(notes.first { $0.text == "Delete" })
        let sut = makeSUT(verses: [ayah(1)])

        await sut.deleteNote(noteToDelete)

        let remainingNotes = try await storedNotes()
        XCTAssertEqual(remainingNotes.map(\.text), ["Keep"])
        XCTAssertNil(sut.error)
    }

    private func makeSUT(verses: some Sequence<AyahNumber>) -> AyahNotesViewModel {
        AyahNotesViewModel(
            verses: Array(verses),
            noteService: noteService
        )
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

#if QURAN_SYNC
import AnnotationsService
import Combine
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import QuranResources
import QuranTextKit
import XCTest
@testable import NotesFeature

@MainActor
final class NotesViewModelTests: XCTestCase {
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

    func test_deleteItem_removesNoteFromMobileSyncDatabase() async throws {
        let ayah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        try await noteService.createNote(body: "Delete me", startAyah: ayah, endAyah: ayah)
        let stored = try await storedNotes()
        let note = try XCTUnwrap(stored.first)
        let item = NoteItem(note: note, quranText: "Verse")
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        let sut = NotesViewModel(
            noteService: noteService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            navigateTo: { _ in },
            editNote: { _ in }
        )

        await sut.deleteItem(item)

        let notes = try await storedNotes()
        XCTAssertTrue(notes.isEmpty)
        XCTAssertNil(sut.error)
    }

    func test_start_observesNotesFromMobileSyncDatabase() async throws {
        let ayah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        try await noteService.createNote(body: "Observed note", startAyah: ayah, endAyah: ayah)
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        let sut = NotesViewModel(
            noteService: noteService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            navigateTo: { _ in },
            editNote: { _ in }
        )
        let observed = expectation(description: "Observes persisted note")
        let observation = sut.$notes.sink { notes in
            if notes.map(\.noteText) == ["Observed note"] {
                observed.fulfill()
            }
        }

        let task = Task { await sut.start() }
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertNil(sut.notes.first?.quranText)
        XCTAssertNil(sut.error)
        task.cancel()
        observation.cancel()
    }

    func test_prepareNotesForSharing_usesShareableVerseText() async throws {
        let ayah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        let note = QuranAnnotations.Note(
            id: "note",
            text: "My note",
            startAyah: ayah,
            endAyah: ayah,
            modifiedDate: Date()
        )
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-translations-database")
        let sut = NotesViewModel(
            noteService: noteService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: QuranResources.quranUthmaniV2Database
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: QuranResources.quranUthmaniV2Database
            ),
            navigateTo: { _ in },
            editNote: { _ in }
        )
        sut.notes = [NoteItem(note: note, quranText: "Verse")]
        QuranContentStatePreferences.shared.quranMode = .arabic

        let text = try await sut.prepareNotesForSharing()

        XCTAssertTrue(text.hasPrefix("My note\n\n"))
        XCTAssertTrue(text.contains("﴿ ١ ﴾"))
        XCTAssertTrue(text.hasSuffix("Al-Fātihah, Ayah 1"))
    }

    private func storedNotes() async throws -> [QuranAnnotations.Note] {
        var iterator = noteService.notesSequence(quran: .hafsMadani1405).makeAsyncIterator()
        return try await iterator.next() ?? []
    }
}
#endif

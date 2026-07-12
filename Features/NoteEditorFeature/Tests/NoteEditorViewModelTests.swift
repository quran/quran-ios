import Analytics
#if QURAN_SYNC
import MobileSyncTestSupport
#endif
import QuranAnnotations
import QuranKit
import XCTest
@testable import AnnotationsService
@testable import NoorUI
@testable import NoteEditorFeature

@MainActor
final class NoteEditorViewModelTests: XCTestCase {
    #if QURAN_SYNC
    private let database = MobileSyncTestDatabase.shared

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    func test_fetchNote_mapsSyncedEditNote() async throws {
        let note = syncedNote(body: "Stored note")
        let sut = makeSyncSUT(mode: .edit(note), text: "ayah text")

        let editableNote = try await sut.viewModel.fetchNote()

        XCTAssertEqual(editableNote.ayahText, "ayah text")
        XCTAssertEqual(editableNote.note, "Stored note")
        XCTAssertEqual(editableNote.selectedColor, .red)
        XCTAssertFalse(editableNote.modifiedSince.isEmpty)
        XCTAssertFalse(sut.viewModel.showsColors)
        XCTAssertEqual(sut.viewModel.deleteConfirmationStyle, .syncedNote)
    }

    func test_invalidShortNote_doesNotSaveOrDismissInSync() async throws {
        let sut = makeSyncSUT(mode: .edit(syncedNote(body: "Stored note")))
        let editableNote = try await sut.viewModel.fetchNote()
        editableNote.note = "short"

        let didSave = await sut.viewModel.commitEditsAndExit(dismissOnSave: true)

        XCTAssertFalse(sut.viewModel.canDismissNote)
        XCTAssertFalse(sut.viewModel.shouldAutoSaveOnDismiss)
        XCTAssertFalse(didSave)
        let notes = try await storedNotes()
        XCTAssertTrue(notes.isEmpty)
        XCTAssertFalse(sut.listener.didDismiss)
    }

    func test_emptyNote_doneDismissesWithoutSavingInSync() async throws {
        let sut = makeSyncSUT(mode: .create(verses: [ayah(1)]))
        _ = try await sut.viewModel.fetchNote()

        let didFinish = await sut.viewModel.commitEditsAndExit(dismissOnSave: true)

        XCTAssertTrue(sut.viewModel.canDismissNote)
        XCTAssertFalse(sut.viewModel.shouldAutoSaveOnDismiss)
        XCTAssertTrue(didFinish)
        let notes = try await storedNotes()
        XCTAssertTrue(notes.isEmpty)
        XCTAssertTrue(sut.listener.didDismiss)
    }

    func test_emptyNote_autoSaveDoesNotSaveOrDismissInSync() async throws {
        let sut = makeSyncSUT(mode: .create(verses: [ayah(1)]))
        _ = try await sut.viewModel.fetchNote()

        let didFinish = await sut.viewModel.commitEditsAndExit(dismissOnSave: false)

        XCTAssertFalse(didFinish)
        let notes = try await storedNotes()
        XCTAssertTrue(notes.isEmpty)
        XCTAssertFalse(sut.listener.didDismiss)
    }

    func test_validDoneSave_updatesSyncedNoteAndDismisses() async throws {
        let note = try await createStoredNote(body: "Stored note")
        let sut = makeSyncSUT(mode: .edit(note))
        let editableNote = try await sut.viewModel.fetchNote()
        editableNote.note = "Updated note"

        let didSave = await sut.viewModel.commitEditsAndExit(dismissOnSave: true)

        XCTAssertTrue(didSave)
        let notes = try await storedNotes()
        let stored = try XCTUnwrap(notes.first)
        XCTAssertEqual(stored.id, note.id)
        XCTAssertEqual(stored.text, "Updated note")
        XCTAssertEqual(sut.analytics.events, [.init(name: "UpdateNoteVersesNum", value: "2")])
        XCTAssertTrue(sut.listener.didDismiss)
    }

    func test_validAutoSave_updatesSyncedNoteWithoutDismissing() async throws {
        let note = try await createStoredNote(body: "Stored note")
        let sut = makeSyncSUT(mode: .edit(note))
        let editableNote = try await sut.viewModel.fetchNote()
        editableNote.note = "Updated note"

        let didSave = await sut.viewModel.commitEditsAndExit(dismissOnSave: false)

        XCTAssertTrue(didSave)
        XCTAssertTrue(sut.viewModel.canDismissNote)
        XCTAssertTrue(sut.viewModel.shouldAutoSaveOnDismiss)
        let notes = try await storedNotes()
        XCTAssertEqual(notes.map(\.text), ["Updated note"])
        XCTAssertFalse(sut.listener.didDismiss)
    }

    func test_createDelete_dismissesWithoutRemovingSyncedNote() async throws {
        let sut = makeSyncSUT(mode: .create(verses: [ayah(1)]))

        await sut.viewModel.forceDelete()

        let notes = try await storedNotes()
        XCTAssertTrue(notes.isEmpty)
        XCTAssertTrue(sut.listener.didDismiss)
    }

    func test_editDelete_removesSyncedNoteAndDismisses() async throws {
        let note = try await createStoredNote(body: "Stored note")
        let sut = makeSyncSUT(mode: .edit(note))

        await sut.viewModel.forceDelete()

        let notes = try await storedNotes()
        XCTAssertTrue(notes.isEmpty)
        XCTAssertTrue(sut.listener.didDismiss)
    }

    func test_createSave_usesSortedVerseRangeAndLogsSelectedVerseCount() async throws {
        let sut = makeSyncSUT(mode: .create(verses: [ayah(3), ayah(1)]))
        let editableNote = try await sut.viewModel.fetchNote()
        editableNote.note = "Created note"

        let didSave = await sut.viewModel.commitEditsAndExit(dismissOnSave: true)

        XCTAssertTrue(didSave)
        let notes = try await storedNotes()
        let stored = try XCTUnwrap(notes.first)
        XCTAssertEqual(stored.text, "Created note")
        XCTAssertEqual(stored.startAyah, ayah(1))
        XCTAssertEqual(stored.endAyah, ayah(3))
        XCTAssertEqual(sut.analytics.events, [.init(name: "UpdateNoteVersesNum", value: "2")])
        XCTAssertTrue(sut.listener.didDismiss)
    }

    func test_editSave_usesSyncedNoteVerseRangeAndLogsRangeVerseCount() async throws {
        let note = try await createStoredNote(body: "Stored note", startAyah: ayah(1), endAyah: ayah(3))
        let sut = makeSyncSUT(mode: .edit(note))
        let editableNote = try await sut.viewModel.fetchNote()
        editableNote.note = "Updated note"

        let didSave = await sut.viewModel.commitEditsAndExit(dismissOnSave: true)

        XCTAssertTrue(didSave)
        let notes = try await storedNotes()
        let stored = try XCTUnwrap(notes.first)
        XCTAssertEqual(stored.id, note.id)
        XCTAssertEqual(stored.text, "Updated note")
        XCTAssertEqual(stored.startAyah, ayah(1))
        XCTAssertEqual(stored.endAyah, ayah(3))
        XCTAssertEqual(sut.analytics.events, [.init(name: "UpdateNoteVersesNum", value: "3")])
    }
    #else
    func test_fetchNote_mapsLegacyNote() async throws {
        let sut = makeLegacySUT(noteBody: "Stored note", color: .blue, text: "ayah text")

        let editableNote = try await sut.viewModel.fetchNote()

        XCTAssertEqual(editableNote.ayahText, "ayah text")
        XCTAssertEqual(editableNote.note, "Stored note")
        XCTAssertEqual(editableNote.selectedColor, .blue)
        XCTAssertFalse(editableNote.modifiedSince.isEmpty)
        XCTAssertTrue(sut.viewModel.showsColors)
        XCTAssertEqual(sut.viewModel.deleteConfirmationStyle, .note)
    }

    func test_invalidShortNote_doesNotSaveOrDismissInLegacy() async throws {
        let sut = makeLegacySUT(noteBody: "Stored note")
        let editableNote = try await sut.viewModel.fetchNote()
        editableNote.note = "short"

        let didSave = await sut.viewModel.commitEditsAndExit(dismissOnSave: true)

        XCTAssertFalse(sut.viewModel.canDismissNote)
        XCTAssertFalse(sut.viewModel.shouldAutoSaveOnDismiss)
        XCTAssertFalse(didSave)
        XCTAssertTrue(sut.noteService.setNoteCalls.isEmpty)
        XCTAssertFalse(sut.listener.didDismiss)
    }

    func test_emptyNote_doneDismissesWithoutSavingInLegacy() async throws {
        let sut = makeLegacySUT(noteBody: "")
        _ = try await sut.viewModel.fetchNote()

        let didFinish = await sut.viewModel.commitEditsAndExit(dismissOnSave: true)

        XCTAssertTrue(sut.viewModel.canDismissNote)
        XCTAssertFalse(sut.viewModel.shouldAutoSaveOnDismiss)
        XCTAssertTrue(didFinish)
        XCTAssertTrue(sut.noteService.setNoteCalls.isEmpty)
        XCTAssertTrue(sut.listener.didDismiss)
    }

    func test_emptyNote_autoSaveDoesNotSaveOrDismissInLegacy() async throws {
        let sut = makeLegacySUT(noteBody: "")
        _ = try await sut.viewModel.fetchNote()

        let didFinish = await sut.viewModel.commitEditsAndExit(dismissOnSave: false)

        XCTAssertFalse(didFinish)
        XCTAssertTrue(sut.noteService.setNoteCalls.isEmpty)
        XCTAssertFalse(sut.listener.didDismiss)
    }

    func test_validDoneSave_savesLegacyNoteAndDismisses() async throws {
        let sut = makeLegacySUT(noteBody: "Stored note", color: .blue)
        let editableNote = try await sut.viewModel.fetchNote()
        editableNote.note = "Updated note"
        editableNote.selectedColor = .green

        let didSave = await sut.viewModel.commitEditsAndExit(dismissOnSave: true)

        XCTAssertTrue(didSave)
        XCTAssertEqual(sut.noteService.setNoteCalls, [
            .init(note: "Updated note", verses: [ayah(1), ayah(2)], color: .green),
        ])
        XCTAssertTrue(sut.listener.didDismiss)
    }

    func test_validAutoSave_savesLegacyNoteWithoutDismissing() async throws {
        let sut = makeLegacySUT(noteBody: "Stored note")
        let editableNote = try await sut.viewModel.fetchNote()
        editableNote.note = "Updated note"

        let didSave = await sut.viewModel.commitEditsAndExit(dismissOnSave: false)

        XCTAssertTrue(didSave)
        XCTAssertTrue(sut.viewModel.canDismissNote)
        XCTAssertTrue(sut.viewModel.shouldAutoSaveOnDismiss)
        XCTAssertEqual(sut.noteService.setNoteCalls.count, 1)
        XCTAssertFalse(sut.listener.didDismiss)
    }

    func test_delete_removesLegacyNoteVersesAndDismisses() async {
        let sut = makeLegacySUT(noteBody: "Stored note")

        await sut.viewModel.forceDelete()

        XCTAssertEqual(sut.noteService.removedVerses, [[ayah(1), ayah(2)]])
        XCTAssertTrue(sut.listener.didDismiss)
    }

    func test_legacyNote_derivesStartAndEndAyahFromPersistedVerses() {
        let note = Note(
            verses: [ayah(3), ayah(1)],
            modifiedDate: Date(timeIntervalSince1970: 1),
            text: "Stored note",
            color: .red
        )

        XCTAssertEqual(note.startAyah, ayah(1))
        XCTAssertEqual(note.endAyah, ayah(3))
    }
    #endif

    private static let quran = Quran.hafsMadani1405

    private static func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: quran, sura: 1, ayah: number)!
    }

    private func ayah(_ number: Int) -> AyahNumber {
        Self.ayah(number)
    }

    #if QURAN_SYNC
    private func makeSyncSUT(
        mode: NoteEditorMode,
        text: String = "ayah text"
    ) -> (viewModel: NoteEditorViewModel, noteService: MobileSyncNoteService, analytics: AnalyticsSpy, listener: ListenerSpy) {
        let noteService = MobileSyncNoteService(quranDataService: database.quranDataService)
        let analytics = AnalyticsSpy()
        let listener = ListenerSpy()
        let viewModel = NoteEditorViewModel(
            noteService: noteService,
            analytics: analytics,
            mode: mode,
            textForVerses: { _ in text }
        )
        viewModel.listener = listener
        return (viewModel, noteService, analytics, listener)
    }

    private func syncedNote(
        localId: String = "note-1",
        body: String,
        startAyah: AyahNumber? = nil,
        endAyah: AyahNumber? = nil
    ) -> Note {
        Note(
            id: localId,
            text: body,
            startAyah: startAyah ?? ayah(1),
            endAyah: endAyah ?? ayah(2),
            modifiedDate: Date(timeIntervalSince1970: 1)
        )
    }

    private func createStoredNote(
        body: String,
        startAyah: AyahNumber? = nil,
        endAyah: AyahNumber? = nil
    ) async throws -> Note {
        let service = MobileSyncNoteService(quranDataService: database.quranDataService)
        try await service.createNote(
            body: body,
            startAyah: startAyah ?? ayah(1),
            endAyah: endAyah ?? ayah(2)
        )
        let notes = try await storedNotes()
        return try XCTUnwrap(notes.first)
    }

    private func storedNotes() async throws -> [Note] {
        let service = MobileSyncNoteService(quranDataService: database.quranDataService)
        var iterator = service.notesSequence(quran: Self.quran).makeAsyncIterator()
        return try await iterator.next() ?? []
    }
    #else
    private func makeLegacySUT(
        noteBody: String,
        color: HighlightColor = .red,
        text: String = "ayah text"
    ) -> (viewModel: NoteEditorViewModel, noteService: LegacyNoteServiceFake, listener: ListenerSpy) {
        let noteService = LegacyNoteServiceFake()
        let listener = ListenerSpy()
        let note = Note(
            verses: [ayah(2), ayah(1)],
            modifiedDate: Date(timeIntervalSince1970: 1),
            text: noteBody,
            color: color
        )
        let viewModel = NoteEditorViewModel(
            noteService: noteService,
            note: note,
            textForVerses: { _ in text }
        )
        viewModel.listener = listener
        return (viewModel, noteService, listener)
    }
    #endif
}

private final class ListenerSpy: NoteEditorListener {
    var didDismiss = false

    func dismissNoteEditor() {
        didDismiss = true
    }
}

#if QURAN_SYNC
private struct AnalyticsEvent: Equatable {
    let name: String
    let value: String
}

private final class AnalyticsSpy: AnalyticsLibrary, @unchecked Sendable {
    private(set) var events: [AnalyticsEvent] = []

    func logEvent(_ name: String, value: String) {
        events.append(.init(name: name, value: value))
    }
}

#else
private final class LegacyNoteServiceFake: NoteEditorLegacyServicing {
    struct SetNoteCall: Equatable {
        let note: String
        let verses: [AyahNumber]
        let color: HighlightColor
    }

    private(set) var setNoteCalls: [SetNoteCall] = []
    private(set) var removedVerses: [[AyahNumber]] = []

    func setNote(_ note: String, verses: [AyahNumber], color: HighlightColor) async throws {
        setNoteCalls.append(.init(note: note, verses: verses, color: color))
    }

    func removeNotes(with verses: [AyahNumber]) async throws {
        removedVerses.append(verses.sorted())
    }
}
#endif

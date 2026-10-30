#if QURAN_SYNC

import AnnotationsService
import Foundation
import MobileSync
import MobileSyncTestSupport
import NoorUI
import NoteEditorFeature
import UIKit
import XCTest
@testable import SettingsFeature

@MainActor
final class HeldItemEditorTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    func test_renamePending_renamesTheHeldCollection() async throws {
        let collection = try await database.quranDataService.createCollection(named: "Morning adhkar")
        let sut = makeSUT()

        await sut.edit(.collection(id: collection.id, name: collection.name))
        XCTAssertEqual(sut.nameAlert, .editing)
        XCTAssertEqual(sut.pendingName, "Morning adhkar")
        sut.pendingName = "  Evening adhkar "
        await sut.renamePending()

        XCTAssertEqual(sut.nameAlert, .hidden)
        XCTAssertNil(sut.error)
        let names = try await collectionNames()
        XCTAssertTrue(names.contains("Evening adhkar"), "\(names)")
    }

    func test_renamePending_keepsTheAlertWithTheReason_whenTheNameIsTaken() async throws {
        let collection = try await database.quranDataService.createCollection(named: "Morning adhkar")
        _ = try await database.quranDataService.createCollection(named: "Duas")
        let sut = makeSUT()

        await sut.edit(.collection(id: collection.id, name: collection.name))
        sut.pendingName = "Duas"
        await sut.renamePending()

        guard case .rejected(.duplicate) = sut.nameAlert else {
            return XCTFail("Expected a duplicate name, got \(sut.nameAlert)")
        }
    }

    func test_editNote_showsAnError_whenTheNoteIsGone() async {
        let sut = makeSUT()

        await sut.edit(.note(id: "deleted-on-another-device"))

        XCTAssertTrue(sut.error is HeldItemEditor.ItemNotFoundError)
    }

    /// A cancelled task usually reads no notes rather than throwing, which must not read as a missing note.
    func test_editNote_staysQuiet_whenItsTaskIsCancelled() async {
        let sut = makeSUT()
        let edit = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await sut.edit(.note(id: "deleted-on-another-device"))
        }

        await edit.value

        XCTAssertNil(sut.error)
    }

    func test_renameReadingBookmark_renamesItsSlot() async throws {
        _ = try await database.quranDataService.setAyahReadingBookmark(slot: .teal, sura: 78, ayah: 1)
        _ = try await database.quranDataService.renameReadingBookmark(slot: .teal, name: "Juz 30", mushaf: .madani1405)
        let sut = makeSUT()

        await sut.edit(.readingBookmark(slot: .teal, name: "Juz 30"))
        XCTAssertEqual(sut.renamingReadingBookmark, .teal)
        XCTAssertEqual(sut.pendingName, "Juz 30")
        sut.pendingName = " Juz Amma "
        await sut.renameReadingBookmark(in: .teal)

        XCTAssertNil(sut.error)
        let bookmarks = try await database.quranDataService.readingBookmarksSequence(mushaf: .madani1405).first { _ in true }
        XCTAssertEqual(bookmarks?.first { $0.slot == .teal }?.name, "Juz Amma")
    }

    /// A rename stamps the bookmark as updated, which would sort it first and sync a change nobody made.
    func test_renameReadingBookmark_skipsTheWrite_whenTheNameIsUnchanged() async throws {
        let original = try await renamedTealBookmark("Juz 30", at: Date(timeIntervalSinceNow: -3600))
        let sut = makeSUT()

        await sut.edit(.readingBookmark(slot: .teal, name: "Juz 30"))
        sut.pendingName = " Juz 30 \n"
        await sut.renameReadingBookmark(in: .teal)

        XCTAssertNil(sut.error)
        let stored = try await storedReadingBookmark(in: .teal)
        XCTAssertEqual(stored?.name, "Juz 30")
        XCTAssertEqual(stored?.lastUpdated, original.lastUpdated)
    }

    func test_renameReadingBookmark_comparesWithTheStoredName_whenItChangedSinceTheListShowedIt() async throws {
        _ = try await renamedTealBookmark("Juz 30", at: Date(timeIntervalSinceNow: -3600))
        let sut = makeSUT()

        await sut.edit(.readingBookmark(slot: .teal, name: "Juz 30"))
        let renamedElsewhere = try await renamedTealBookmark("Juz Amma", at: Date(timeIntervalSinceNow: -60))
        sut.pendingName = "Juz Amma"
        await sut.renameReadingBookmark(in: .teal)

        XCTAssertNil(sut.error)
        let stored = try await storedReadingBookmark(in: .teal)
        XCTAssertEqual(stored?.name, "Juz Amma")
        XCTAssertEqual(stored?.lastUpdated, renamedElsewhere.lastUpdated)
    }

    func test_renameReadingBookmark_clearsTheName_whenItIsEmptied() async throws {
        let original = try await renamedTealBookmark("Juz 30", at: Date(timeIntervalSinceNow: -3600))
        let sut = makeSUT()

        await sut.edit(.readingBookmark(slot: .teal, name: "Juz 30"))
        sut.pendingName = "  "
        await sut.renameReadingBookmark(in: .teal)

        XCTAssertNil(sut.error)
        let stored = try await storedReadingBookmark(in: .teal)
        XCTAssertNil(stored?.name)
        XCTAssertNotEqual(stored?.lastUpdated, original.lastUpdated)
    }

    // MARK: Rows

    func test_rowEdit_renamesReadingBookmarks_thatAreTooLongOrRefused() {
        let lookup = HeldItemLookup(readingBookmarks: [
            MobileSyncReadingBookmark(id: "rb", slot: .orange, placement: .unplaced, name: "Ramadan", lastUpdated: Date()),
        ])

        let rows = HeldItemRow.rows(
            for: [heldItem(.readingBookmark, id: "rb", reason: .tooLong), heldItem(.readingBookmark, id: "gone", reason: .tooLong)],
            lookup: lookup
        )

        XCTAssertEqual(rows.map(\.edit), [.readingBookmark(slot: .orange, name: "Ramadan"), nil])
    }

    func test_rowEdit_opensTheNote_whenEditingCanFixIt() {
        let lookup = HeldItemLookup(notes: [
            MobileSyncNote(id: "n1", body: "Hi", ranges: [.init(startSura: 1, startAyah: 1, endSura: 1, endAyah: 1)], lastUpdated: Date()),
        ])

        let rows = HeldItemRow.rows(
            for: [heldItem(.note, id: "n1", reason: .tooShort), heldItem(.note, id: "gone", reason: .tooShort)],
            lookup: lookup
        )

        XCTAssertEqual(rows.map(\.edit), [.note(id: "n1"), nil])
    }

    func test_rowEdit_skipsNotesWhoseVersesAreWrong() {
        let lookup = HeldItemLookup(notes: [
            MobileSyncNote(id: "n1", body: "Hi", ranges: [.init(startSura: 1, startAyah: 1, endSura: 1, endAyah: 1)], lastUpdated: Date()),
        ])

        let rows = HeldItemRow.rows(for: [heldItem(.note, id: "n1", reason: .invalidRange)], lookup: lookup)

        XCTAssertNil(rows.first?.edit)
    }

    func test_rowEdit_renamesUserCollections_butNotFavoritesOrReadOnlyOnes() {
        let lookup = HeldItemLookup(collections: [
            MobileSyncCollection(id: "c1", name: "Duas", lastUpdated: Date(), isDefault: false, isSystem: false, isReadOnly: false),
            MobileSyncCollection(id: "fav", name: "Favorites", lastUpdated: Date(), isDefault: true, isSystem: false, isReadOnly: false),
            MobileSyncCollection(id: "ro", name: "Green", lastUpdated: Date(), isDefault: false, isSystem: false, isReadOnly: true),
        ])

        let rows = HeldItemRow.rows(
            for: [
                heldItem(.collection, id: "c1", reason: .reservedName),
                heldItem(.collection, id: "fav", reason: .rejectedByServer),
                heldItem(.collection, id: "ro", reason: .readOnly),
            ],
            lookup: lookup
        )

        XCTAssertEqual(rows.map(\.edit), [.collection(id: "c1", name: "Duas"), nil, nil])
    }

    // MARK: Private

    private let database = MobileSyncTestDatabase.shared

    private func makeSUT() -> HeldItemEditor {
        let container = AppDependenciesStub()
        return HeldItemEditor(
            noteService: MobileSyncNoteService(quranDataService: database.quranDataService),
            collectionService: AyahBookmarkCollectionService(quranDataService: database.quranDataService),
            readingBookmarkService: MobileSyncReadingBookmarkService(quranDataService: database.quranDataService),
            readingPreferences: .shared,
            noteEditorBuilder: NoteEditorBuilder(container: container),
            navigationController: UINavigationController()
        )
    }

    private func renamedTealBookmark(_ name: String, at timestamp: Date) async throws -> MobileSyncReadingBookmark {
        _ = try await database.quranDataService.setAyahReadingBookmark(slot: .teal, sura: 78, ayah: 1, timestamp: timestamp)
        return try await database.quranDataService.renameReadingBookmark(slot: .teal, name: name, mushaf: .madani1405, timestamp: timestamp)
    }

    private func storedReadingBookmark(in slot: MobileSyncReadingBookmarkSlot) async throws -> MobileSyncReadingBookmark? {
        let bookmarks = try await database.quranDataService.readingBookmarksSequence(mushaf: .madani1405).first { _ in true }
        return bookmarks?.first { $0.slot == slot }
    }

    private func collectionNames() async throws -> [String] {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        return try await iterator.next()?.map(\.collection.name) ?? []
    }
}

#endif

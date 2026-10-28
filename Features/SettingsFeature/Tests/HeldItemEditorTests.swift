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

    // MARK: Rows

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
            noteEditorBuilder: NoteEditorBuilder(container: container),
            navigationController: UINavigationController()
        )
    }

    private func collectionNames() async throws -> [String] {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        return try await iterator.next()?.map(\.collection.name) ?? []
    }
}

#endif

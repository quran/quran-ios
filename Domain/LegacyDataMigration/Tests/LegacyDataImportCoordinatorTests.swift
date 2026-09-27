#if QURAN_SYNC
//
//  LegacyDataImportCoordinatorTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-27.
//

import CoreData
import CoreDataPersistence
import CoreDataPersistenceTestSupport
import LegacyDataPersistence
import MobileSync
import MobileSyncTestSupport
import XCTest
@testable import LegacyDataMigration

final class LegacyDataImportCoordinatorTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        LegacyImportPreferences.reset()
        try await database.reset()
        store = TemporaryCoreDataStore()
        stack = store.stack()
        sut = makeCoordinator()
    }

    override func tearDown() async throws {
        observation?.cancel()
        observation = nil
        // Wait for any scan before resetting the database it imports into.
        await sut?.disable()
        sut = nil
        stack = nil
        store = nil
        try await database.reset()
        LegacyImportPreferences.reset()
        try await super.tearDown()
    }

    func test_importNow_importsLegacyDataIntoMobileSync() async throws {
        try stack.write { context in
            // Page 121 is 5:77 in Madani 1405 (also the unknown-mushaf default) and 5:78 in Madani 1440.
            for (page, mushafID): (Int32, Int16) in [(2, 0), (121, 0), (121, 1), (121, 7)] {
                _ = context.newPageBookmark(page: page, mushafID: mushafID, modifiedOn: 100)
            }
            _ = context.newLastPage(page: 3, modifiedOn: 200)
            context.note("Legacy note", color: 2, verses: [(2, 3), (2, 1)], modifiedOn: 300)
            context.note(" ", color: 3, verses: [(3, 1)], modifiedOn: 400)
        }

        try await sut.importNow()

        let collections = try await first(database.quranDataService.collectionsWithBookmarksSequence())
        let oldPageBookmarks = try XCTUnwrap(collections.first { $0.collection.name == "Old Page Bookmarks" })
        // The two sources anchored at 5:77 become one membership.
        XCTAssertEqual(oldPageBookmarks.bookmarks.map { "\($0.sura):\($0.ayah)" }.sorted(), ["2:1", "5:77", "5:78"])
        XCTAssertEqual(collections.first { $0.collection.isDefault }?.bookmarks.count, 0)

        let sessions = try await first(database.quranDataService.readingSessionsSequence())
        XCTAssertEqual(sessions.map { "\($0.sura):\($0.ayah)" }, ["2:6"])

        let notes = try await storedNotes()
        XCTAssertEqual(notes.map(\.body), ["Legacy note"])
        XCTAssertEqual(notes.map { "\($0.startSura):\($0.startAyah)-\($0.endSura):\($0.endAyah)" }, ["2:1-2:3"])

        let highlights = try await first(database.quranDataService.highlightsSequence())
        XCTAssertEqual(highlights.map { "\($0.sura):\($0.ayah) \($0.color.name)" }.sorted(), ["2:1 BLUE", "2:3 BLUE", "3:1 YELLOW"])
    }

    func test_repeatedImport_doesNotRecreateDeletedNote() async throws {
        try stack.write { context in
            context.note("Delete me", color: 0, verses: [(1, 1)], modifiedOn: 10)
        }
        try await sut.importNow()
        let importedNotes = try await storedNotes()
        let note = try XCTUnwrap(importedNotes.first)
        try await database.quranDataService.deleteNote(id: note.id)

        try await sut.importNow()

        let notes = try await storedNotes()
        XCTAssertEqual(notes, [])
    }

    func test_importNow_importsNoteOnceItsVersesArrive() async throws {
        try stack.write { context in
            _ = context.newNote("Arrives in parts", modifiedOn: 10)
        }
        try await sut.importNow()
        let notesBeforeArrival = try await storedNotes()
        XCTAssertEqual(notesBeforeArrival, [])

        try stack.write { context in
            let note = try XCTUnwrap(try context.allNotes().first)
            note.addToVerses(context.newVerse(sura: 2, ayah: 255))
        }
        try await sut.importNow()

        let notes = try await storedNotes()
        XCTAssertEqual(notes.map(\.body), ["Arrives in parts"])
    }

    func test_importNow_throwsWhenTheStoreCannotOpen_thenRetrySucceeds() async throws {
        try store.corrupt()

        do {
            try await sut.importNow()
            XCTFail("A failed read must not complete as an empty import")
        } catch {}

        store.removeStoreFiles()
        try await sut.importNow()
    }

    func test_start_importsLaterStoreChanges() async throws {
        await sut.start()
        try await sut.importNow()
        let imported = expectation(forNotes: ["Late CloudKit arrival"])

        // Only the change subscription can import this; the test requests no scan.
        try stack.write { context in
            context.note("Late CloudKit arrival", color: 0, verses: [(18, 10)], modifiedOn: 10)
        }

        await fulfillment(of: [imported], timeout: 10)
    }

    func test_disable_stopsLaterImports() async throws {
        try stack.write { context in
            context.note("Written before logout", color: 0, verses: [(1, 1)], modifiedOn: 10)
        }

        await sut.disable()
        try await sut.importNow()

        let notes = try await storedNotes()
        XCTAssertEqual(notes, [])
    }

    func test_disable_persistsAcrossLaunches() async throws {
        await sut.disable()
        try store.corrupt()

        // A new launch creates a new coordinator; it must not read the store.
        try await makeCoordinator().importNow()
    }

    func test_reopenedStore_keepsImportedContentAfterRelaunch() async throws {
        try stack.write { context in
            context.note("Imported once", color: 1, verses: [(2, 1), (2, 2)], modifiedOn: 20)
        }
        try await sut.importNow()
        let notesBefore = try await storedNotes()

        // A relaunch opens a new stack, reader, and coordinator on the same store.
        sut = nil
        stack = store.stack()
        sut = makeCoordinator()
        try await sut.importNow()

        let notesAfter = try await storedNotes()
        XCTAssertEqual(notesAfter.map(\.id), notesBefore.map(\.id))
    }

    // MARK: Private

    private let database = MobileSyncTestDatabase.shared
    private var store: TemporaryCoreDataStore!
    private var stack: CoreDataStack!
    private var sut: LegacyDataImportCoordinator!
    private var observation: Task<Void, Never>?

    private func makeCoordinator() -> LegacyDataImportCoordinator {
        LegacyDataImportCoordinator(reader: CoreDataLegacyDataReader(stack: stack), quranDataService: database.quranDataService)
    }

    private func storedNotes() async throws -> [Note_] {
        try await first(database.quranDataService.notesSequence())
    }

    private func first<Element>(_ sequence: MobileSyncAsyncSequence<[Element]>) async throws -> [Element] {
        let iterator = sequence.makeAsyncIterator()
        return try await iterator.next() ?? []
    }

    /// Fulfills when MobileSync publishes notes with exactly these bodies.
    private func expectation(forNotes bodies: [String]) -> XCTestExpectation {
        let imported = expectation(description: "MobileSync publishes \(bodies)")
        let notes = database.quranDataService.notesSequence()
        observation = Task {
            do {
                for try await notes in notes where notes.map(\.body).sorted() == bodies.sorted() {
                    imported.fulfill()
                    return
                }
            } catch {}
        }
        return imported
    }
}

private extension NSManagedObjectContext {
    func note(_ text: String, color: Int32, verses: [(Int32, Int32)], modifiedOn: TimeInterval) {
        let note = newNote(text, modifiedOn: modifiedOn)
        note.color = color
        for (sura, ayah) in verses {
            note.addToVerses(newVerse(sura: sura, ayah: ayah))
        }
    }
}
#endif

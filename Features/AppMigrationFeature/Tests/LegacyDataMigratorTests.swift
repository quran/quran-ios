#if QURAN_SYNC
//
//  LegacyDataMigratorTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-27.
//

import AppMigrationFeature
import AppMigrator
import CoreDataPersistence
import CoreDataPersistenceTestSupport
import LegacyDataPersistence
import MobileSync
import MobileSyncTestSupport
import XCTest
@testable import LegacyDataMigration

final class LegacyDataMigratorTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        LegacyImportPreferences.reset()
        store = TemporaryCoreDataStore()
        stack = store.stack()
    }

    override func tearDown() async throws {
        stack = nil
        store = nil
        try await database.reset()
        LegacyImportPreferences.reset()
        try await super.tearDown()
    }

    func test_execute_importsLegacyData() async throws {
        try stack.write { context in
            let note = context.newNote("Legacy note", modifiedOn: 1)
            note.addToVerses(context.newVerse(sura: 1, ayah: 1))
        }

        await makeMigrator().execute(update: .update(from: "2.9.0", to: "3.0.0"))

        let notes = try await storedNotes()
        XCTAssertEqual(notes.map(\.body), ["Legacy note"])
    }

    func test_execute_finishesWhenTheStoreStaysUnreadable() async throws {
        try store.corrupt()

        await makeMigrator().execute(update: .update(from: "2.9.0", to: "3.0.0"))

        let notes = try await storedNotes()
        XCTAssertEqual(notes, [])
    }

    // MARK: Private

    private let database = MobileSyncTestDatabase.shared
    private var store: TemporaryCoreDataStore!
    private var stack: CoreDataStack!

    private func makeMigrator() -> LegacyDataMigrator {
        let coordinator = LegacyDataImportCoordinator(
            reader: CoreDataLegacyDataReader(stack: stack),
            quranDataService: database.quranDataService
        )
        return LegacyDataMigrator(coordinator: coordinator, retryDelay: 0)
    }

    private func storedNotes() async throws -> [Note_] {
        let iterator = database.quranDataService.notesSequence().makeAsyncIterator()
        return try await iterator.next() ?? []
    }
}
#endif

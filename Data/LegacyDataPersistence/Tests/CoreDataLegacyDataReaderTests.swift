#if QURAN_SYNC
//
//  CoreDataLegacyDataReaderTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-24.
//

import CoreData
import CoreDataModel
import CoreDataPersistence
import CoreDataPersistenceTestSupport
import LegacyDataPersistence
import MobileSync
import QuranAnnotations
import XCTest

final class CoreDataLegacyDataReaderTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        store = TemporaryCoreDataStore()
    }

    override func tearDown() {
        observation?.cancel()
        observation = nil
        store = nil
        super.tearDown()
    }

    // MARK: - Store

    func test_importData_readsFirstModelVersionStoreAfterMigration() async throws {
        var firstVersionStack: CoreDataStack? = store.stack(modelUrl: TemporaryCoreDataStore.firstModelURL)
        try XCTUnwrap(firstVersionStack).write { context in
            context.insert("MO_PageBookmark", ["page": 3, "createdOn": date(10), "modifiedOn": date(20)])
            context.insert("MO_LastPage", ["page": 3, "createdOn": date(30), "modifiedOn": date(40)])
            context.note("First version", color: 3, verses: [(2, 255)], created: date(50), modified: date(60))
        }
        firstVersionStack = nil

        let data = try await importData()

        XCTAssertEqual(data, PersistenceImportData(
            collections: [ImportCollection(name: collectionName, lastUpdated: date(20), createdAt: date(10))],
            collectionBookmarks: [ImportCollectionAyahBookmark(collectionName: collectionName, sura: 2, ayah: 6, lastUpdated: date(20), createdAt: date(10))],
            readingSessions: [ImportReadingSession(sura: 2, ayah: 6, lastUpdated: date(40), createdAt: date(30))],
            notes: [ImportNote(body: "First version", startSura: 2, startAyah: 255, endSura: 2, endAyah: 255, lastUpdated: date(60), createdAt: date(50))],
            highlights: [ImportAyahHighlight(sura: 2, ayah: 255, color: .yellow, lastUpdated: date(60), createdAt: date(50))],
            readingBookmarks: []
        ))
    }

    func test_importData_ofEmptyStore_isEmpty() async throws {
        let data = try await importData()

        XCTAssertEqual(data, emptyImport)
    }

    func test_importData_throwsWhenStoreCannotOpen_thenRecoversOnRetry() async throws {
        try store.corrupt()
        let reader = CoreDataLegacyDataReader(stack: store.stack())

        do {
            _ = try await reader.importData()
            XCTFail("A failed open must not produce an empty import")
        } catch {}

        store.removeStoreFiles()
        let data = try await reader.importData()
        XCTAssertEqual(data, emptyImport)
    }

    func test_importData_performsNoApplicationSaves() async throws {
        let stack = store.stack()
        try stack.write { context in
            context.note("No verses", verses: [])
        }
        let writesBeforeReading = try historyTransactionCount(in: stack)

        _ = try await CoreDataLegacyDataReader(stack: stack).importData()
        _ = try await CoreDataLegacyDataReader(stack: stack).importData()

        XCTAssertEqual(try historyTransactionCount(in: stack), writesBeforeReading)
    }

    func test_changes_subscribesBeforeTheStoreLoads() async throws {
        let stack = store.stack()
        let changed = expectation(forChangeOf: CoreDataLegacyDataReader(stack: stack))

        // Writing loads the store after the subscription was created.
        try stack.write { context in
            context.insert("MO_PageBookmark", ["page": 1, "modifiedOn": date(1)])
        }

        await fulfillment(of: [changed], timeout: 5)
    }

    func test_importData_isDeterministic() async throws {
        let stack = store.stack()
        try stack.write { context in
            context.insert("MO_PageBookmark", ["page": 10])
            context.insert("MO_LastPage", ["page": 10, "mushafID": 1, "modifiedOn": date(1)])
            context.note("Stable", verses: [(2, 2), (2, 1)])
        }
        let reader = CoreDataLegacyDataReader(stack: stack)

        let first = try await reader.importData()
        let second = try await reader.importData()

        XCTAssertEqual(first, second)
    }

    // MARK: - Page bookmarks

    func test_pageBookmarks_resolveFirstVerseForEverySourceMushaf() async throws {
        // Page 121 starts on a different verse in every layout.
        let data = try await importData { context in
            context.insert("MO_PageBookmark", ["page": 121, "mushafID": 0, "modifiedOn": date(1)])
            context.insert("MO_PageBookmark", ["page": 121, "mushafID": 1, "modifiedOn": date(2)])
            context.insert("MO_PageBookmark", ["page": 121, "mushafID": 2, "modifiedOn": date(3)])
        }

        XCTAssertEqual(data.collectionBookmarks.map(verse), ["5:77", "5:78", "5:69"])
    }

    func test_pageBookmarks_unknownOrMissingMushafUsesMadani1405() async throws {
        let data = try await importData { context in
            context.insert("MO_PageBookmark", ["page": 121, "mushafID": 7])
            context.insert("MO_PageBookmark", ["page": 121])
        }

        XCTAssertEqual(data.collectionBookmarks.map(verse), ["5:77", "5:77"])
    }

    func test_pageBookmarks_unresolvablePagesAreLeftOut() async throws {
        let data = try await importData { context in
            context.insert("MO_PageBookmark", ["mushafID": 0])
            context.insert("MO_PageBookmark", ["page": 0, "mushafID": 0])
            context.insert("MO_PageBookmark", ["page": 605, "mushafID": 0])
        }

        XCTAssertEqual(data, emptyImport)
    }

    func test_pageBookmarks_becomeOldPageBookmarksMemberships() async throws {
        let pages = [2, 50, 100, 200, 300]
        let data = try await importData { context in
            for (index, page) in pages.enumerated() {
                context.insert("MO_PageBookmark", ["page": page, "createdOn": date(Double(100 + index)), "modifiedOn": date(Double(1000 + index))])
            }
        }

        XCTAssertEqual(data.collections, [ImportCollection(
            name: collectionName, lastUpdated: date(1004), createdAt: date(100)
        )])
        XCTAssertEqual(Set(data.collectionBookmarks.map(\.collectionName)), [collectionName])
        XCTAssertEqual(data.collectionBookmarks.map(verse), ["2:1", "3:1", "4:135", "9:80", "18:54"])
        XCTAssertEqual(data.readingSessions, [])
    }

    func test_dates_fallBackToCreationThenEpoch() async throws {
        let data = try await importData { context in
            context.insert("MO_PageBookmark", ["page": 2, "createdOn": date(10), "modifiedOn": date(20)])
            context.insert("MO_PageBookmark", ["page": 3, "createdOn": date(30)])
            context.insert("MO_PageBookmark", ["page": 4, "modifiedOn": date(40)])
            context.insert("MO_PageBookmark", ["page": 5])
        }

        let dates = data.collectionBookmarks.sorted { $0.ayah < $1.ayah }.map { [$0.lastUpdated, $0.createdAt] }
        // Pages 2 to 5 start at 2:1, 2:6, 2:17, and 2:25.
        XCTAssertEqual(dates, [[date(20), date(10)], [date(30), date(30)], [date(40), date(40)], [date(0), date(0)]])
        XCTAssertEqual(data.collections.map(\.createdAt), [date(0)])
        XCTAssertEqual(data.collections.map(\.lastUpdated), [date(40)])
    }

    // MARK: - Last pages

    func test_lastPages_becomeReadingSessionsAtFirstVerse() async throws {
        let data = try await importData { context in
            context.insert("MO_LastPage", ["page": 3, "mushafID": 0, "createdOn": date(10), "modifiedOn": date(20)])
            context.insert("MO_LastPage", ["page": 121, "mushafID": 2, "createdOn": date(30)])
            context.insert("MO_LastPage", ["page": 121, "mushafID": 9, "modifiedOn": date(40)])
        }

        XCTAssertEqual(Set(data.readingSessions), [
            ImportReadingSession(sura: 2, ayah: 6, lastUpdated: date(20), createdAt: date(10)),
            ImportReadingSession(sura: 5, ayah: 69, lastUpdated: date(30), createdAt: date(30)),
            ImportReadingSession(sura: 5, ayah: 77, lastUpdated: date(40), createdAt: date(40)),
        ])
        XCTAssertEqual(data.collections, [])
    }

    func test_lastPages_withoutDatesOrValidPageAreLeftOut() async throws {
        let data = try await importData { context in
            context.insert("MO_LastPage", ["page": 3, "mushafID": 0])
            context.insert("MO_LastPage", ["page": 999, "mushafID": 0, "createdOn": date(1), "modifiedOn": date(2)])
        }

        XCTAssertEqual(data, emptyImport)
    }

    // MARK: - Notes

    func test_note_becomesInclusiveRangeAndHighlightsPerVerse() async throws {
        let data = try await importData { context in
            context.note("Remember", color: 1, verses: [(2, 3), (2, 1)], created: date(5), modified: date(6))
        }

        XCTAssertEqual(data.notes, [ImportNote(
            body: "Remember", startSura: 2, startAyah: 1, endSura: 2, endAyah: 3, lastUpdated: date(6), createdAt: date(5)
        )])
        XCTAssertEqual(data.highlights, [
            ImportAyahHighlight(sura: 2, ayah: 1, color: .green, lastUpdated: date(6), createdAt: date(5)),
            ImportAyahHighlight(sura: 2, ayah: 3, color: .green, lastUpdated: date(6), createdAt: date(5)),
        ])
    }

    func test_note_crossSuraSelectionUsesFirstAndLastInQuranOrder() async throws {
        let data = try await importData { context in
            context.note("Across", verses: [(3, 1), (2, 286), (2, 285)])
        }

        XCTAssertEqual(data.notes.map { "\($0.startSura):\($0.startAyah)-\($0.endSura):\($0.endAyah)" }, ["2:285-3:1"])
        XCTAssertEqual(data.highlights.map(verse), ["2:285", "2:286", "3:1"])
    }

    func test_note_preservesOriginalText() async throws {
        let body = "  First line\n\n  second   line  "
        let data = try await importData { context in
            context.note(body, verses: [(1, 1)])
        }

        XCTAssertEqual(data.notes.map(\.body), [body])
    }

    func test_note_blankTextProducesHighlightsOnly() async throws {
        let data = try await importData { context in
            context.note(" \n ", color: 4, verses: [(2, 255)])
            context.note(nil, color: 3, verses: [(2, 256)])
        }

        XCTAssertEqual(data.notes, [])
        XCTAssertEqual(data.highlights.sorted { $0.ayah < $1.ayah }.map(\.color), [.purple, .yellow])
    }

    func test_note_invalidVerseLeavesOutTextButKeepsValidHighlights() async throws {
        let data = try await importData { context in
            context.note("Partially arrived", color: 2, verses: [(2, 1), (2, nil), (1, 8), (115, 1)])
        }

        XCTAssertEqual(data.notes, [])
        XCTAssertEqual(data.highlights.map(verse), ["2:1"])
    }

    func test_note_withoutVersesIsLeftOut() async throws {
        let data = try await importData { context in
            context.note("Waiting", verses: [])
        }

        XCTAssertEqual(data, emptyImport)
    }

    func test_note_colorsMapIndependentlyWithPinkDefault() async throws {
        let colors: [Int?] = [0, nil, 99, -1, 1, 2, 3, 4]
        let data = try await importData { context in
            for (index, color) in colors.enumerated() {
                context.note(nil, color: color, verses: [(2, index + 1)])
            }
        }

        let highlights = data.highlights.sorted { $0.ayah < $1.ayah }
        XCTAssertEqual(highlights.map(\.color), [.pink, .pink, .pink, .pink, .green, .blue, .yellow, .purple])
        XCTAssertEqual(highlights.map(\.lastUpdated), Array(repeating: date(0), count: colors.count))
    }

    func test_note_duplicateVerseEntriesProduceOneHighlight() async throws {
        let data = try await importData { context in
            context.note("Twice", verses: [(2, 1), (2, 1)])
        }

        XCTAssertEqual(data.highlights.map(verse), ["2:1"])
        XCTAssertEqual(data.notes.map { "\($0.endSura):\($0.endAyah)" }, ["2:1"])
    }

    // MARK: Private

    private var store: TemporaryCoreDataStore!
    private var observation: Task<Void, Never>?

    private let collectionName = AyahBookmarkCollection.oldPageBookmarksName

    private let emptyImport = PersistenceImportData(
        collections: [], collectionBookmarks: [], readingSessions: [], notes: [], highlights: [], readingBookmarks: []
    )

    /// Writes the records to a real store and reads them back.
    private func importData(_ records: (NSManagedObjectContext) -> Void = { _ in }) async throws -> PersistenceImportData {
        let stack = store.stack()
        try stack.write { records($0) }
        return try await CoreDataLegacyDataReader(stack: stack).importData()
    }

    private func expectation(forChangeOf reader: CoreDataLegacyDataReader) -> XCTestExpectation {
        let changed = expectation(description: "The source store reports a change")
        let changes = reader.changes()
        observation = Task {
            for await _ in changes {
                changed.fulfill()
                return
            }
        }
        return changed
    }

    private func historyTransactionCount(in stack: CoreDataStack) throws -> Int {
        let context = try stack.openBackgroundContext()
        return try context.performAndWait {
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: .distantPast)
            let result = try context.execute(request) as? NSPersistentHistoryResult
            let transactions = result?.result as? [NSPersistentHistoryTransaction] ?? []
            return transactions.count
        }
    }

    private func verse(_ bookmark: ImportCollectionAyahBookmark) -> String {
        "\(bookmark.sura):\(bookmark.ayah)"
    }

    private func verse(_ highlight: ImportAyahHighlight) -> String {
        "\(highlight.sura):\(highlight.ayah)"
    }
}

private func date(_ seconds: TimeInterval) -> Date {
    Date(timeIntervalSince1970: seconds)
}

private extension NSManagedObjectContext {
    /// Inserts by entity name so fixtures work with every model version and can leave values missing.
    @discardableResult
    func insert(_ entityName: String, _ values: [String: Any]) -> NSManagedObject {
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: self)!
        let object = NSManagedObject(entity: entity, insertInto: self)
        for (key, value) in values {
            object.setValue(value, forKey: key)
        }
        return object
    }

    func note(_ text: String?, color: Int? = 0, verses: [(Int, Int?)], created: Date? = nil, modified: Date? = nil) {
        var values: [String: Any] = [:]
        values["note"] = text
        values["color"] = color
        values["createdOn"] = created
        values["modifiedOn"] = modified
        let note = insert("MO_Note", values)
        for (sura, ayah) in verses {
            var verseValues: [String: Any] = ["sura": sura]
            verseValues["ayah"] = ayah
            insert("MO_Verse", verseValues).setValue(note, forKey: "note")
        }
    }
}
#endif

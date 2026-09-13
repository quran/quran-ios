#if QURAN_SYNC
import AnnotationsService
import Combine
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import QuranViewFeature

@MainActor
final class QuranAnnotationsObserverTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        noteService = MobileSyncNoteService(quranDataService: database.quranDataService)
        highlightService = MobileSyncAyahHighlightService(quranDataService: database.quranDataService)
        collectionService = AyahBookmarkCollectionService(quranDataService: database.quranDataService)
        readingBookmarkService = MobileSyncReadingBookmarkService(quranDataService: database.quranDataService)
    }

    override func tearDown() async throws {
        try await database.reset()
        noteService = nil
        highlightService = nil
        collectionService = nil
        readingBookmarkService = nil
        try await super.tearDown()
    }

    func test_start_observesPersistedNotesAndIntersections() async throws {
        try await noteService.createNote(body: "Stored note", startAyah: ayah(1), endAyah: ayah(2))
        let highlights = QuranHighlightsService()
        let observer = makeObserver(highlights: highlights)
        defer { observer.stop() }

        observer.start()
        await waitForHighlights(highlights) { $0.noteVerses == [self.ayah(1), self.ayah(2)] }

        XCTAssertEqual(observer.notes(interacting: [ayah(2)]).map(\.text), ["Stored note"])
        XCTAssertTrue(observer.notes(interacting: [ayah(3)]).isEmpty)
        XCTAssertEqual(highlights.highlights.annotationsByVerse, [ayah(1): [.note], ayah(2): [.note]])
    }

    func test_noteDeletionRemovesObservedAnnotation() async throws {
        try await noteService.createNote(body: "Delete me", startAyah: ayah(1), endAyah: ayah(1))
        let highlights = QuranHighlightsService()
        let observer = makeObserver(highlights: highlights)
        defer { observer.stop() }
        observer.start()
        await waitForHighlights(highlights) { $0.noteVerses == [self.ayah(1)] }
        let note = try XCTUnwrap(observer.notes.first)

        try await noteService.removeNote(note)
        await waitForHighlights(highlights) { $0.noteVerses.isEmpty }

        XCTAssertTrue(observer.notes.isEmpty)
    }

    func test_start_appliesPersistedHighlights() async throws {
        try await highlightService.setHighlight(.green, for: [ayah(1)])
        let highlights = QuranHighlightsService()
        let observer = makeObserver(highlights: highlights)
        defer { observer.stop() }

        observer.start()
        await waitForHighlights(highlights) { $0.highlightVerses[self.ayah(1)] == .green }

        XCTAssertEqual(highlights.highlights.highlightVerses, [ayah(1): .green])
    }

    func test_start_observesCollectionsSeparatelyFromHighlights() async throws {
        try await collectionService.createCollection(named: "Duas")
        var iterator = collectionService.collectionsSequence().makeAsyncIterator()
        let collections = try await iterator.next() ?? []
        let duas = try XCTUnwrap(collections.first { $0.collection.name == "Duas" })
        try await collectionService.addAyahBookmarkToCollection(collectionId: duas.collection.id, ayah: ayah(1))
        let highlights = QuranHighlightsService()
        let observer = makeObserver(highlights: highlights)
        defer { observer.stop() }

        observer.start()
        await waitForHighlights(highlights) { $0.collectionVerses == [self.ayah(1)] }

        XCTAssertEqual(observer.collections.count, 2)
        XCTAssertTrue(observer.collections.contains { $0.collection.isDefault })
        XCTAssertTrue(observer.collections.contains { $0.collection.name == "Duas" })
        XCTAssertEqual(highlights.highlights.annotationsByVerse, [ayah(1): [.collection]])
        XCTAssertTrue(highlights.highlights.highlightVerses.isEmpty)
    }

    func test_start_publishesPageBookmarksWithoutAyahAnnotations() async throws {
        let page = Quran.hafsMadani1405.pages[40]
        try await readingBookmarkService.addReadingBookmark(at: .page(page), slot: .coral)
        let highlights = QuranHighlightsService()
        let observer = makeObserver(highlights: highlights)
        defer { observer.stop() }
        let observed = expectation(description: "Publishes page bookmark")
        let observation = observer.$readingBookmarks.first { $0.map(\.slot) == [.coral] }
            .sink { _ in observed.fulfill() }
        defer { observation.cancel() }

        observer.start()
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertEqual(observer.readingBookmarks.map(\.slot), [.coral])
        XCTAssertEqual(observer.latestReadingBookmark(at: [.page(page)])?.slot, .coral)
        XCTAssertTrue(highlights.highlights.annotationsByVerse.isEmpty)
    }

    func test_start_publishesSubsequentReadingBookmarkChanges() async throws {
        let highlights = QuranHighlightsService()
        let observer = makeObserver(highlights: highlights)
        defer { observer.stop() }
        observer.start()

        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(255)), slot: .teal)
        await waitForHighlights(highlights) { $0.readingBookmarks.map(\.slot) == [.teal] }

        XCTAssertEqual(observer.readingBookmarks.map(\.slot), [.teal])
        XCTAssertEqual(highlights.highlights.annotationsByVerse, [ayah(255): [.readingBookmark(.teal)]])
    }

    func test_clearingReadingBookmarkRemovesPublishedPin() async throws {
        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(5)), slot: .coral)
        let highlights = QuranHighlightsService()
        let observer = makeObserver(highlights: highlights)
        defer { observer.stop() }
        observer.start()
        await waitForHighlights(highlights) { $0.readingBookmarks.map(\.slot) == [.coral] }

        try await readingBookmarkService.clearReadingBookmark(in: .coral)
        await waitForHighlights(highlights) { $0.readingBookmarks.isEmpty }

        XCTAssertTrue(observer.readingBookmarks.isEmpty)
        XCTAssertTrue(highlights.highlights.annotationsByVerse.isEmpty)
    }

    func test_clearingOnePinPreservesAnotherOnTheSameAyah() async throws {
        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(5)), slot: .coral)
        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(255)), slot: .teal)
        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(5)), slot: .indigo)
        let highlights = QuranHighlightsService()
        let observer = makeObserver(highlights: highlights)
        defer { observer.stop() }
        observer.start()
        await waitForHighlights(highlights) { $0.readingBookmarks.count == 3 }
        XCTAssertEqual(highlights.highlights.annotationsByVerse, [
            ayah(5): [.readingBookmark(.coral), .readingBookmark(.indigo)],
            ayah(255): [.readingBookmark(.teal)],
        ])

        try await readingBookmarkService.clearReadingBookmark(in: .coral)
        await waitForHighlights(highlights) { $0.readingBookmarks.count == 2 }

        XCTAssertEqual(highlights.highlights.annotationsByVerse, [
            ayah(5): [.readingBookmark(.indigo)], ayah(255): [.readingBookmark(.teal)],
        ])
        XCTAssertEqual(observer.latestReadingBookmark(at: [.ayah(ayah(5)), .ayah(ayah(6))])?.slot, .indigo)
    }

    func test_independentStreamsPreserveOtherAnnotationsAndTransientHighlights() async throws {
        let verse = ayah(1)
        try await noteService.createNote(body: "Note", startAyah: verse, endAyah: verse)
        try await highlightService.setHighlight(.green, for: [verse])
        try await readingBookmarkService.addReadingBookmark(at: .ayah(verse), slot: .teal)
        var iterator = collectionService.collectionsSequence().makeAsyncIterator()
        let collections = try await iterator.next() ?? []
        let collection = try XCTUnwrap(collections.first { $0.collection.isDefault })
        try await collectionService.addAyahBookmarkToCollection(collectionId: collection.collection.id, ayah: verse)
        let highlights = QuranHighlightsService()
        highlights.highlights.navigationVerse = verse
        highlights.highlights.readingVerses = [verse]
        highlights.highlights.shareVerses = [ayah(2)]
        highlights.highlights.pointedWord = Word(verse: verse, wordNumber: 1)
        let observer = makeObserver(highlights: highlights)
        defer { observer.stop() }
        observer.start()
        await waitForHighlights(highlights) {
            $0.highlightVerses[verse] == .green
                && $0.annotationsByVerse[verse] == [.note, .collection, .readingBookmark(.teal)]
        }
        let note = try XCTUnwrap(observer.notes.first)

        try await noteService.removeNote(note)
        await waitForHighlights(highlights) { $0.noteVerses.isEmpty }

        XCTAssertEqual(highlights.highlights.annotationsByVerse[verse], [.collection, .readingBookmark(.teal)])
        XCTAssertEqual(highlights.highlights.highlightVerses[verse], .green)
        XCTAssertEqual(highlights.highlights.navigationVerse, verse)
        XCTAssertEqual(highlights.highlights.readingVerses, [verse])
        XCTAssertEqual(highlights.highlights.shareVerses, [ayah(2)])
        XCTAssertEqual(highlights.highlights.pointedWord, Word(verse: verse, wordNumber: 1))
    }

    func test_runningStreamsDoNotRetainObserver() async throws {
        let verse = ayah(1)
        try await noteService.createNote(body: "Note", startAyah: verse, endAyah: verse)
        try await highlightService.setHighlight(.green, for: [verse])
        try await readingBookmarkService.addReadingBookmark(at: .ayah(verse), slot: .teal)
        var iterator = collectionService.collectionsSequence().makeAsyncIterator()
        let collections = try await iterator.next() ?? []
        let collection = try XCTUnwrap(collections.first { $0.collection.isDefault })
        try await collectionService.addAyahBookmarkToCollection(collectionId: collection.collection.id, ayah: verse)
        let highlights = QuranHighlightsService()
        var observer: QuranAnnotationsObserver? = makeObserver(highlights: highlights)
        weak var weakObserver = observer
        observer?.start()
        await waitForHighlights(highlights) {
            $0.highlightVerses[verse] == .green
                && $0.annotationsByVerse[verse] == [.note, .collection, .readingBookmark(.teal)]
        }

        observer = nil

        XCTAssertNil(weakObserver)
    }

    func test_stopPreventsUpdatesAndRestartLoadsLatestState() async throws {
        let highlights = QuranHighlightsService()
        let observer = makeObserver(highlights: highlights)
        defer { observer.stop() }
        try await noteService.createNote(body: "Before stop", startAyah: ayah(1), endAyah: ayah(1))
        observer.start()
        await waitForHighlights(highlights) { $0.noteVerses == [self.ayah(1)] }
        observer.stop()
        let unexpectedUpdate = expectation(description: "Stopped observer does not publish")
        unexpectedUpdate.isInverted = true
        let observation = highlights.$highlights.dropFirst().sink { _ in unexpectedUpdate.fulfill() }

        try await noteService.createNote(body: "While stopped", startAyah: ayah(2), endAyah: ayah(2))
        await fulfillment(of: [unexpectedUpdate], timeout: 0.1)
        observation.cancel()
        XCTAssertEqual(observer.notes.map(\.text), ["Before stop"])

        observer.start()
        await waitForHighlights(highlights) { $0.noteVerses == [self.ayah(1), self.ayah(2)] }
        XCTAssertEqual(observer.notes.count, 2)
    }

    func test_immediateRestartSurvivesOldTaskCancellation() async throws {
        let highlights = QuranHighlightsService()
        let observer = makeObserver(highlights: highlights)
        defer { observer.stop() }
        observer.start()
        observer.stop()
        observer.start()
        observer.start()

        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(1)), slot: .coral)
        await waitForHighlights(highlights) { $0.readingBookmarks.map(\.slot) == [.coral] }
        try await readingBookmarkService.clearReadingBookmark(in: .coral)
        await waitForHighlights(highlights) { $0.readingBookmarks.isEmpty }

        XCTAssertTrue(observer.readingBookmarks.isEmpty)
    }

    private let database = MobileSyncTestDatabase.shared
    private var noteService: MobileSyncNoteService!
    private var highlightService: MobileSyncAyahHighlightService!
    private var collectionService: AyahBookmarkCollectionService!
    private var readingBookmarkService: MobileSyncReadingBookmarkService!

    private func makeObserver(highlights: QuranHighlightsService) -> QuranAnnotationsObserver {
        QuranAnnotationsObserver(
            noteService: noteService,
            highlightService: highlightService,
            collectionService: collectionService,
            readingBookmarkService: readingBookmarkService,
            quran: .hafsMadani1405,
            highlightsService: highlights
        )
    }

    private func waitForHighlights(
        _ service: QuranHighlightsService,
        matching predicate: @escaping (QuranHighlights) -> Bool
    ) async {
        let observed = expectation(description: "Observes expected Quran annotations")
        let observation = service.$highlights.first(where: predicate).sink { _ in observed.fulfill() }
        await fulfillment(of: [observed], timeout: 2)
        observation.cancel()
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: number)!
    }
}
#endif

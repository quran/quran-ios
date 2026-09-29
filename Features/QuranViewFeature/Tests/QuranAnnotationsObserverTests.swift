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
        let overlayService = VerseOverlayService()
        let observer = makeObserver(overlayService: overlayService)
        defer { observer.stop() }

        observer.start()
        await waitForOverlays(overlayService) { $0.notedVerses == [self.ayah(1), self.ayah(2)] }

        XCTAssertEqual(observer.notes(interacting: [ayah(2)]).map(\.text), ["Stored note"])
        XCTAssertTrue(observer.notes(interacting: [ayah(3)]).isEmpty)
        XCTAssertEqual(overlayService.overlays.annotationsByVerse, [ayah(1): [.note], ayah(2): [.note]])
    }

    func test_noteDeletionRemovesObservedAnnotation() async throws {
        try await noteService.createNote(body: "Delete me", startAyah: ayah(1), endAyah: ayah(1))
        let overlayService = VerseOverlayService()
        let observer = makeObserver(overlayService: overlayService)
        defer { observer.stop() }
        observer.start()
        await waitForOverlays(overlayService) { $0.notedVerses == [self.ayah(1)] }
        let note = try XCTUnwrap(observer.notes.first)

        try await noteService.removeNote(note)
        await waitForOverlays(overlayService) { $0.notedVerses.isEmpty }

        XCTAssertTrue(observer.notes.isEmpty)
    }

    func test_start_appliesPersistedHighlights() async throws {
        try await highlightService.setHighlight(.green, for: [ayah(1)])
        let overlayService = VerseOverlayService()
        let observer = makeObserver(overlayService: overlayService)
        defer { observer.stop() }

        observer.start()
        await waitForOverlays(overlayService) { $0.colorHighlights[self.ayah(1)] == .green }

        XCTAssertEqual(overlayService.overlays.colorHighlights, [ayah(1): .green])
    }

    func test_start_observesCollectionsSeparatelyFromHighlights() async throws {
        try await collectionService.createCollection(named: "Duas")
        var iterator = collectionService.collectionsSequence().makeAsyncIterator()
        let collections = try await iterator.next() ?? []
        let duas = try XCTUnwrap(collections.first { $0.name == "Duas" })
        try await collectionService.addAyahBookmarkToCollection(collectionId: duas.id, ayah: ayah(1))
        let overlayService = VerseOverlayService()
        let observer = makeObserver(overlayService: overlayService)
        defer { observer.stop() }

        observer.start()
        await waitForOverlays(overlayService) { $0.collectionVerses == [self.ayah(1)] }

        XCTAssertEqual(observer.collections.count, 2)
        XCTAssertTrue(observer.collections.contains { $0.isDefault })
        XCTAssertTrue(observer.collections.contains { $0.name == "Duas" })
        XCTAssertEqual(overlayService.overlays.annotationsByVerse, [ayah(1): [.collection]])
        XCTAssertTrue(overlayService.overlays.colorHighlights.isEmpty)
    }

    func test_start_publishesPageBookmarksWithoutAyahAnnotations() async throws {
        let page = Quran.hafsMadani1405.pages[40]
        try await readingBookmarkService.addReadingBookmark(at: .page(page), slot: .teal)
        let overlayService = VerseOverlayService()
        let observer = makeObserver(overlayService: overlayService)
        defer { observer.stop() }
        let observed = expectation(description: "Publishes page bookmark")
        let observation = observer.$readingBookmarks.first { $0.map(\.slot) == [.teal] }
            .sink { _ in observed.fulfill() }
        defer { observation.cancel() }

        observer.start()
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertEqual(observer.readingBookmarks.map(\.slot), [.teal])
        XCTAssertEqual(observer.latestReadingBookmark(at: [.page(page)])?.slot, .teal)
        XCTAssertTrue(overlayService.overlays.annotationsByVerse.isEmpty)
    }

    func test_start_publishesSubsequentReadingBookmarkChanges() async throws {
        let overlayService = VerseOverlayService()
        let observer = makeObserver(overlayService: overlayService)
        defer { observer.stop() }
        observer.start()

        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(255)), slot: .orange)
        await waitForOverlays(overlayService) { $0.readingBookmarks.map(\.slot) == [.orange] }

        XCTAssertEqual(observer.readingBookmarks.map(\.slot), [.orange])
        XCTAssertEqual(overlayService.overlays.annotationsByVerse, [ayah(255): [.readingBookmark(.orange)]])
    }

    func test_clearingReadingBookmarkRemovesPublishedPin() async throws {
        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(5)), slot: .teal)
        let overlayService = VerseOverlayService()
        let observer = makeObserver(overlayService: overlayService)
        defer { observer.stop() }
        observer.start()
        await waitForOverlays(overlayService) { $0.readingBookmarks.map(\.slot) == [.teal] }

        try await readingBookmarkService.clearReadingBookmark(in: .teal)
        await waitForOverlays(overlayService) { $0.readingBookmarks.isEmpty }

        XCTAssertTrue(observer.readingBookmarks.isEmpty)
        XCTAssertTrue(overlayService.overlays.annotationsByVerse.isEmpty)
    }

    func test_clearingOnePinPreservesAnotherOnTheSameAyah() async throws {
        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(5)), slot: .teal)
        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(255)), slot: .orange)
        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(5)), slot: .red)
        let overlayService = VerseOverlayService()
        let observer = makeObserver(overlayService: overlayService)
        defer { observer.stop() }
        observer.start()
        await waitForOverlays(overlayService) { $0.readingBookmarks.count == 3 }
        XCTAssertEqual(overlayService.overlays.annotationsByVerse, [
            ayah(5): [.readingBookmark(.teal), .readingBookmark(.red)],
            ayah(255): [.readingBookmark(.orange)],
        ])

        try await readingBookmarkService.clearReadingBookmark(in: .teal)
        await waitForOverlays(overlayService) { $0.readingBookmarks.count == 2 }

        XCTAssertEqual(overlayService.overlays.annotationsByVerse, [
            ayah(5): [.readingBookmark(.red)], ayah(255): [.readingBookmark(.orange)],
        ])
        XCTAssertEqual(observer.latestReadingBookmark(at: [.ayah(ayah(5)), .ayah(ayah(6))])?.slot, .red)
    }

    func test_independentStreamsPreserveOtherAnnotationsAndTransientHighlights() async throws {
        let verse = ayah(1)
        try await noteService.createNote(body: "Note", startAyah: verse, endAyah: verse)
        try await highlightService.setHighlight(.green, for: [verse])
        try await readingBookmarkService.addReadingBookmark(at: .ayah(verse), slot: .orange)
        var iterator = collectionService.collectionsSequence().makeAsyncIterator()
        let collections = try await iterator.next() ?? []
        let collection = try XCTUnwrap(collections.first { $0.isDefault })
        try await collectionService.addAyahBookmarkToCollection(collectionId: collection.id, ayah: verse)
        let overlayService = VerseOverlayService()
        overlayService.overlays.navigationTarget = verse
        overlayService.overlays.playingVerses = [verse]
        overlayService.overlays.selectedVerses = [ayah(2)]
        overlayService.overlays.pointedWord = Word(verse: verse, wordNumber: 1)
        let observer = makeObserver(overlayService: overlayService)
        defer { observer.stop() }
        observer.start()
        await waitForOverlays(overlayService) {
            $0.colorHighlights[verse] == .green
                && $0.annotationsByVerse[verse] == [.note, .collection, .readingBookmark(.orange)]
        }
        let note = try XCTUnwrap(observer.notes.first)

        try await noteService.removeNote(note)
        await waitForOverlays(overlayService) { $0.notedVerses.isEmpty }

        XCTAssertEqual(overlayService.overlays.annotationsByVerse[verse], [.collection, .readingBookmark(.orange)])
        XCTAssertEqual(overlayService.overlays.colorHighlights[verse], .green)
        XCTAssertEqual(overlayService.overlays.navigationTarget, verse)
        XCTAssertEqual(overlayService.overlays.playingVerses, [verse])
        XCTAssertEqual(overlayService.overlays.selectedVerses, [ayah(2)])
        XCTAssertEqual(overlayService.overlays.pointedWord, Word(verse: verse, wordNumber: 1))
    }

    func test_runningStreamsDoNotRetainObserver() async throws {
        let verse = ayah(1)
        try await noteService.createNote(body: "Note", startAyah: verse, endAyah: verse)
        try await highlightService.setHighlight(.green, for: [verse])
        try await readingBookmarkService.addReadingBookmark(at: .ayah(verse), slot: .orange)
        var iterator = collectionService.collectionsSequence().makeAsyncIterator()
        let collections = try await iterator.next() ?? []
        let collection = try XCTUnwrap(collections.first { $0.isDefault })
        try await collectionService.addAyahBookmarkToCollection(collectionId: collection.id, ayah: verse)
        let overlayService = VerseOverlayService()
        var observer: QuranAnnotationsObserver? = makeObserver(overlayService: overlayService)
        weak var weakObserver = observer
        observer?.start()
        await waitForOverlays(overlayService) {
            $0.colorHighlights[verse] == .green
                && $0.annotationsByVerse[verse] == [.note, .collection, .readingBookmark(.orange)]
        }

        observer = nil

        XCTAssertNil(weakObserver)
    }

    func test_stopPreventsUpdatesAndRestartLoadsLatestState() async throws {
        let overlayService = VerseOverlayService()
        let observer = makeObserver(overlayService: overlayService)
        defer { observer.stop() }
        try await noteService.createNote(body: "Before stop", startAyah: ayah(1), endAyah: ayah(1))
        observer.start()
        await waitForOverlays(overlayService) { $0.notedVerses == [self.ayah(1)] }
        observer.stop()
        let unexpectedUpdate = expectation(description: "Stopped observer does not publish")
        unexpectedUpdate.isInverted = true
        let observation = overlayService.$overlays.dropFirst().sink { _ in unexpectedUpdate.fulfill() }

        try await noteService.createNote(body: "While stopped", startAyah: ayah(2), endAyah: ayah(2))
        await fulfillment(of: [unexpectedUpdate], timeout: 0.1)
        observation.cancel()
        XCTAssertEqual(observer.notes.map(\.text), ["Before stop"])

        observer.start()
        await waitForOverlays(overlayService) { $0.notedVerses == [self.ayah(1), self.ayah(2)] }
        XCTAssertEqual(observer.notes.count, 2)
    }

    func test_immediateRestartSurvivesOldTaskCancellation() async throws {
        let overlayService = VerseOverlayService()
        let observer = makeObserver(overlayService: overlayService)
        defer { observer.stop() }
        observer.start()
        observer.stop()
        observer.start()
        observer.start()

        try await readingBookmarkService.addReadingBookmark(at: .ayah(ayah(1)), slot: .teal)
        await waitForOverlays(overlayService) { $0.readingBookmarks.map(\.slot) == [.teal] }
        try await readingBookmarkService.clearReadingBookmark(in: .teal)
        await waitForOverlays(overlayService) { $0.readingBookmarks.isEmpty }

        XCTAssertTrue(observer.readingBookmarks.isEmpty)
    }

    private let database = MobileSyncTestDatabase.shared
    private var noteService: MobileSyncNoteService!
    private var highlightService: MobileSyncAyahHighlightService!
    private var collectionService: AyahBookmarkCollectionService!
    private var readingBookmarkService: MobileSyncReadingBookmarkService!

    private func makeObserver(overlayService: VerseOverlayService) -> QuranAnnotationsObserver {
        QuranAnnotationsObserver(
            noteService: noteService,
            highlightService: highlightService,
            collectionService: collectionService,
            readingBookmarkService: readingBookmarkService,
            quran: .hafsMadani1405,
            overlayService: overlayService
        )
    }

    private func waitForOverlays(
        _ service: VerseOverlayService,
        matching predicate: @escaping (VerseOverlays) -> Bool
    ) async {
        let observed = expectation(description: "Observes expected Quran annotations")
        let observation = service.$overlays.first(where: predicate).sink { _ in observed.fulfill() }
        await fulfillment(of: [observed], timeout: 2)
        observation.cancel()
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: number)!
    }
}
#endif

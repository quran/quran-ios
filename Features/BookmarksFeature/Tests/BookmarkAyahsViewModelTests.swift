#if QURAN_SYNC
import MobileSync
import MobileSyncTestSupport
import NoorUI
import QuranAnnotations
import QuranKit
import XCTest
@testable import AnnotationsService
@testable import BookmarksFeature

@MainActor
final class BookmarkAyahsViewModelTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    func test_selectingHighlightImmediatelyPersistsAcrossSuras() async throws {
        let fixture = try await makeFixture()
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            highlights: fixture.highlights,
            ayahBookmarkCollectionService: fixture.collectionService,
            ayahHighlightService: fixture.highlightService
        )

        await sut.selectHighlight(.green)

        let stored = try await storedHighlights()
        XCTAssertEqual(stored[verses[0]], .green)
        XCTAssertEqual(stored[verses[1]], .green)
        XCTAssertEqual(sut.highlightSelection, .color(.green))
    }

    func test_togglingMixedCollectionImmediatelyAddsAllSelectedAyahs() async throws {
        let fixture = try await makeFixture()
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            highlights: fixture.highlights,
            ayahBookmarkCollectionService: fixture.collectionService,
            ayahHighlightService: fixture.highlightService
        )
        let study = try XCTUnwrap(sut.displayedCollections.first { $0.collection.name == "Study" })
        XCTAssertEqual(sut.collectionSelection(for: study), .mixed)

        await sut.toggleCollection(study)

        let stored = try await storedCollections()
        XCTAssertEqual(bookmarkedAyahs(in: stored, named: "Study"), ["1:7", "2:1"])
        XCTAssertEqual(sut.collectionSelection(for: study), .selected)
    }

    func test_removingHighlightImmediatelyRemovesSelectedAyahs() async throws {
        let fixture = try await makeFixture()
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            highlights: fixture.highlights,
            ayahBookmarkCollectionService: fixture.collectionService,
            ayahHighlightService: fixture.highlightService
        )
        await sut.selectHighlight(nil)

        let stored = try await storedHighlights()
        XCTAssertNil(stored[verses[0]])
        XCTAssertNil(stored[verses[1]])
        XCTAssertEqual(sut.highlightSelection, .none)
    }

    func test_mixedHighlightSelectionCanBeRemoved() async throws {
        let fixture = try await makeFixture()
        try await fixture.highlightService.removeHighlight(for: [verses[1]])
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            highlights: try await storedHighlights(),
            ayahBookmarkCollectionService: fixture.collectionService,
            ayahHighlightService: fixture.highlightService
        )
        XCTAssertEqual(sut.highlightSelection, .mixed([.red]))
        XCTAssertEqual(sut.partiallySelectedHighlightColors, [.red])

        await sut.selectHighlight(nil)

        let stored = try await storedHighlights()
        XCTAssertNil(stored[verses[0]])
        XCTAssertEqual(sut.highlightSelection, .none)
    }

    func test_mixedHighlightSelectionExposesEveryPartiallySelectedColor() async throws {
        let fixture = try await makeFixture()
        try await fixture.highlightService.setHighlight(.green, for: [verses[1]])
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            highlights: try await storedHighlights(),
            ayahBookmarkCollectionService: fixture.collectionService,
            ayahHighlightService: fixture.highlightService
        )

        XCTAssertEqual(sut.highlightSelection, .mixed([.red, .green]))
        XCTAssertEqual(sut.partiallySelectedHighlightColors, [.red, .green])
    }

    func test_titleShowsSingleAyah() {
        let title = BookmarkAyahsViewController.title(for: [verses[0]])

        XCTAssertEqual(title?.accessibilityText, verses[0].localizedName)
    }

    func test_titleShowsAyahRange() {
        let title = BookmarkAyahsViewController.title(for: verses)

        XCTAssertEqual(
            title?.accessibilityText,
            "\(verses[0].localizedName) - \(verses[1].localizedName)"
        )
    }

    private var verses: [AyahNumber] {
        [
            AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 7)!,
            AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 1)!,
        ]
    }

    private func makeFixture() async throws -> (
        collectionService: AyahBookmarkCollectionService,
        highlightService: MobileSyncAyahHighlightService,
        collections: [AyahBookmarkCollection],
        highlights: [AyahNumber: HighlightColor]
    ) {
        let collectionService = makeCollectionService()
        let highlightService = makeHighlightService()
        try await collectionService.createCollection(named: "Study")

        var collections = try await mappedCollections()
        let study = try XCTUnwrap(collections.first { $0.collection.name == "Study" })
        for verse in verses {
            try await highlightService.setHighlight(.red, for: [verse])
        }
        try await collectionService.addAyahBookmarkToCollection(collectionId: study.collection.id, ayah: verses[0])
        collections = try await mappedCollections()
        return (collectionService, highlightService, collections, try await storedHighlights(using: highlightService))
    }

    private func mappedCollections() async throws -> [AyahBookmarkCollection] {
        AyahBookmarkCollectionService.collections(
            from: try await storedCollections(),
            quran: .hafsMadani1405
        )
    }

    private func storedCollections() async throws -> [CollectionWithAyahBookmarks] {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        return try await iterator.next() ?? []
    }

    private func storedHighlights(
        using service: MobileSyncAyahHighlightService? = nil
    ) async throws -> [AyahNumber: HighlightColor] {
        let service = service ?? makeHighlightService()
        var iterator = service.highlightsSequence().makeAsyncIterator()
        return try await iterator.next() ?? [:]
    }

    private func makeCollectionService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: database.quranDataService)
    }

    private func makeHighlightService() -> MobileSyncAyahHighlightService {
        MobileSyncAyahHighlightService(quranDataService: database.quranDataService)
    }

    private func bookmarkedAyahs(
        in collections: [CollectionWithAyahBookmarks],
        named name: String
    ) -> Set<String> {
        let collection = collections.first {
            $0.collection.name.caseInsensitiveCompare(name) == .orderedSame
        }
        return Set(collection?.bookmarks.map { "\($0.sura):\($0.ayah)" } ?? [])
    }
}
#endif

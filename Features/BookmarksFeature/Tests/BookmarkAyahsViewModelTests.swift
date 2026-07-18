#if QURAN_SYNC
import MobileSync
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
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
            ayahBookmarkCollectionService: fixture.service
        )

        await sut.selectHighlight(.green)

        let stored = try await storedCollections()
        XCTAssertEqual(bookmarkedAyahs(in: stored, named: HighlightColor.green.collectionName), ["1:7", "2:1"])
        XCTAssertEqual(bookmarkedAyahs(in: stored, named: HighlightColor.red.collectionName), [])
        XCTAssertEqual(sut.highlightSelection, .color(.green))
    }

    func test_togglingMixedCollectionImmediatelyAddsAllSelectedAyahs() async throws {
        let fixture = try await makeFixture()
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            ayahBookmarkCollectionService: fixture.service
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
            ayahBookmarkCollectionService: fixture.service
        )
        await sut.selectHighlight(nil)

        let stored = try await storedCollections()
        XCTAssertEqual(bookmarkedAyahs(in: stored, named: HighlightColor.red.collectionName), [])
        XCTAssertEqual(bookmarkedAyahs(in: stored, named: HighlightColor.green.collectionName), [])
        XCTAssertEqual(sut.highlightSelection, .none)
    }

    func test_mixedHighlightSelectionCanBeRemoved() async throws {
        let fixture = try await makeFixture()
        let red = try XCTUnwrap(fixture.collections.first { $0.kind == .colored(.red) })
        try await fixture.service.removeAyahs(
            [verses[1]],
            fromCollectionWithID: red.collection.id
        )
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: try await mappedCollections(),
            ayahBookmarkCollectionService: fixture.service
        )
        XCTAssertEqual(sut.highlightSelection, .mixed([.red]))
        XCTAssertEqual(sut.partiallySelectedHighlightColors, [.red])

        await sut.selectHighlight(nil)

        let stored = try await storedCollections()
        XCTAssertEqual(bookmarkedAyahs(in: stored, named: HighlightColor.red.collectionName), [])
        XCTAssertEqual(sut.highlightSelection, .none)
    }

    func test_mixedHighlightSelectionExposesEveryPartiallySelectedColor() async throws {
        let fixture = try await makeFixture()
        try await fixture.service.setHighlight(.green, for: [verses[1]])
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: try await mappedCollections(),
            ayahBookmarkCollectionService: fixture.service
        )

        XCTAssertEqual(sut.highlightSelection, .mixed([.red, .green]))
        XCTAssertEqual(sut.partiallySelectedHighlightColors, [.red, .green])
    }

    private var verses: [AyahNumber] {
        [
            AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 7)!,
            AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 1)!,
        ]
    }

    private func makeFixture() async throws -> (
        service: AyahBookmarkCollectionService,
        collections: [AyahBookmarkCollection]
    ) {
        let service = AyahBookmarkCollectionService(quranDataService: database.quranDataService)
        try await service.createCollection(named: HighlightColor.red.collectionName)
        try await service.createCollection(named: HighlightColor.green.collectionName)
        try await service.createCollection(named: "Study")

        var collections = try await mappedCollections()
        let red = try XCTUnwrap(collections.first { $0.kind == .colored(.red) })
        let study = try XCTUnwrap(collections.first { $0.collection.name == "Study" })
        for verse in verses {
            try await service.addAyahBookmarkToCollection(collectionId: red.collection.id, ayah: verse)
        }
        try await service.addAyahBookmarkToCollection(collectionId: study.collection.id, ayah: verses[0])
        collections = try await mappedCollections()
        return (service, collections)
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

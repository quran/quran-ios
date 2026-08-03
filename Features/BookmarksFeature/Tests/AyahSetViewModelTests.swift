#if QURAN_SYNC
import Combine
import MobileSync
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import QuranResources
import QuranTextKit
import XCTest
@testable import AnnotationsService
@testable import BookmarksFeature

@MainActor
final class AyahSetViewModelTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private let oldPageBookmarksCollectionName = "Old Page Bookmarks"

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    func test_start_observesCollectionsFromMobileSyncDatabase() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let stored = try await storedCollections {
            $0.contains { !$0.collection.isDefault }
        }
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405)
                .first { !$0.collection.isDefault }
        )
        let sut = makeSUT(collection: collection, service: service)
        let observed = expectation(description: "Observes persisted collection")
        let observation = sut.$content
            .filter { $0.title == "Favorites" }
            .prefix(1)
            .sink { _ in observed.fulfill() }

        let task = Task { await sut.start() }
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertNil(sut.error)
        task.cancel()
        observation.cancel()
    }

    func test_start_loadsArabicTextForCollectionBookmarks() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let storedCollection = try await firstCollection()
        let ayah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1))
        try await service.addAyahBookmarkToCollection(
            collectionId: storedCollection.collection.id,
            ayah: ayah
        )
        let collection = try await firstCollection()
        let sut = makeSUT(collection: collection, service: service)
        let retrieved = expectation(description: "Retrieves Arabic text")
        let observation = sut.$ayahTexts
            .filter { $0[ayah]?.text.isEmpty == false }
            .prefix(1)
            .sink { _ in retrieved.fulfill() }

        let task = Task { await sut.start() }
        await fulfillment(of: [retrieved], timeout: 2)

        XCTAssertFalse(try XCTUnwrap(sut.ayahTexts[ayah]).text.isEmpty)
        XCTAssertNil(sut.error)
        task.cancel()
        observation.cancel()
    }

    func test_deleteBookmark_removesOldPageBookmarkFromMobileSyncDatabase() async throws {
        let service = makeService()
        try await service.createCollection(named: oldPageBookmarksCollectionName)
        var stored = try await storedCollections()
        let storedCollection = try XCTUnwrap(
            stored.first { $0.collection.name == oldPageBookmarksCollectionName }
        )
        try await service.addAyahBookmarkToCollection(
            collectionId: storedCollection.collection.id,
            ayah: AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        )
        stored = try await storedCollections {
            $0.first { $0.collection.name == oldPageBookmarksCollectionName }?.bookmarks.count == 1
        }
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService
                .collections(from: stored, quran: .hafsMadani1405)
                .first { $0.collection.name == oldPageBookmarksCollectionName }
        )
        let bookmark = try XCTUnwrap(collection.bookmarks.first)
        let sut = makeSUT(collection: collection, service: service)

        await sut.removeAyah(bookmark.ayah)

        stored = try await storedCollections {
            $0.first { $0.collection.name == oldPageBookmarksCollectionName }?.bookmarks.isEmpty == true
        }
        let updatedCollection = try XCTUnwrap(
            stored.first { $0.collection.name == oldPageBookmarksCollectionName }
        )
        XCTAssertTrue(updatedCollection.bookmarks.isEmpty)
        XCTAssertNil(sut.error)
    }

    func test_renamePendingCollection_updatesRealMobileSyncDatabase() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let collection = try await firstCollection()
        let sut = makeSUT(collection: collection, service: service)
        sut.pendingName = " Duas "

        await sut.renamePending()

        let renamedCollection = try await firstCollection()
        XCTAssertEqual(renamedCollection.collection.name, "Duas")
        XCTAssertNil(sut.error)
    }

    func test_requestDeleteCollection_deletesEmptyCollectionAndNotifiesListener() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let collection = try await firstCollection()
        var didDeleteCollection = false
        let sut = makeSUT(
            collection: collection,
            service: service,
            collectionDeleted: { didDeleteCollection = true }
        )

        await sut.requestDelete()

        let stored = try await storedCollections {
            $0.count == 1 && $0[0].collection.isDefault
        }
        XCTAssertEqual(stored.map(\.collection.name), ["Default"])
        XCTAssertTrue(stored[0].collection.isDefault)
        XCTAssertTrue(didDeleteCollection)
        XCTAssertFalse(sut.isPresentingDeleteConfirmation)
        XCTAssertNil(sut.error)
    }

    func test_requestDeleteCollection_requiresConfirmationForNonEmptyCollection() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let storedCollection = try await firstCollection()
        try await service.addAyahBookmarkToCollection(
            collectionId: storedCollection.collection.id,
            ayah: AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        )
        let stored = try await storedCollections {
            $0.first { $0.collection.name == "Favorites" }?.bookmarks.count == 1
        }
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405)
                .first { $0.collection.name == "Favorites" }
        )
        var didDeleteCollection = false
        let sut = makeSUT(
            collection: collection,
            service: service,
            collectionDeleted: { didDeleteCollection = true }
        )

        await sut.requestDelete()

        XCTAssertTrue(sut.isPresentingDeleteConfirmation)
        let unchangedCollections = try await storedCollections()
        XCTAssertTrue(unchangedCollections.contains { $0.collection.id == collection.id })
        XCTAssertFalse(didDeleteCollection)
        XCTAssertNil(sut.error)
    }

    func test_navigateToBookmark_navigatesToBookmarkedAyah() async throws {
        let service = makeService()
        try await service.createCollection(named: "Highlights")
        let storedCollection = try await firstCollection()
        let ayah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 255))
        try await service.addAyahBookmarkToCollection(
            collectionId: storedCollection.collection.id,
            ayah: ayah
        )
        let collection = try await firstCollection()
        let bookmark = try XCTUnwrap(collection.bookmarks.first)
        var navigatedAyah: AyahNumber?
        let sut = makeSUT(
            collection: collection,
            service: service,
            navigateToAyah: { navigatedAyah = $0 }
        )

        sut.navigateTo(bookmark.ayah)

        XCTAssertEqual(navigatedAyah, ayah)
    }

    func test_start_observesSelectedHighlightsAndLoadsArabicText() async throws {
        let service = makeHighlightService()
        let redAyah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 255))
        let greenAyah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1))
        try await service.setHighlight(.red, for: [redAyah])
        try await service.setHighlight(.green, for: [greenAyah])
        let sut = makeHighlightSUT(color: .red, service: service)
        let observed = expectation(description: "Observes selected highlights and Arabic text")
        let observation = Publishers.CombineLatest(sut.$content, sut.$ayahTexts)
            .filter { content, texts in
                content.ayahs == [redAyah] && texts[redAyah]?.text.isEmpty == false
            }
            .prefix(1)
            .sink { _ in observed.fulfill() }

        let task = Task { await sut.start() }
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertEqual(sut.content.title, HighlightColor.red.localizedName)
        XCTAssertEqual(sut.content.ayahs, [redAyah])
        XCTAssertEqual(sut.content.highlightColor, .red)
        XCTAssertNil(sut.ayahTexts[greenAyah])
        XCTAssertNil(sut.error)
        task.cancel()
        observation.cancel()
    }

    func test_removeAyah_removesOnlySelectedHighlight() async throws {
        let service = makeHighlightService()
        let redAyah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1))
        let greenAyah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 2))
        try await service.setHighlight(.red, for: [redAyah])
        try await service.setHighlight(.green, for: [greenAyah])
        let sut = makeHighlightSUT(color: .red, service: service)

        await sut.removeAyah(redAyah)

        let highlights = try await storedHighlights(using: service) {
            $0[redAyah] == nil && $0[greenAyah] == .green
        }
        XCTAssertNil(highlights[redAyah])
        XCTAssertEqual(highlights[greenAyah], .green)
        XCTAssertNil(sut.error)
    }

    private func makeSUT(
        collection: AyahBookmarkCollection,
        service: AyahBookmarkCollectionService? = nil,
        quranTextDataService: QuranTextDataService? = nil,
        navigateToAyah: @escaping (AyahNumber) -> Void = { _ in },
        collectionDeleted: @escaping () -> Void = {}
    ) -> AyahSetViewModel {
        let service = service ?? makeService()
        return AyahSetViewModel(
            dataSource: BookmarkCollectionAyahSetDataSource(
                collection: collection,
                service: service
            ),
            quranTextDataService: quranTextDataService ?? makeQuranTextDataService(),
            navigateToAyah: navigateToAyah,
            dataSourceDeleted: collectionDeleted
        )
    }

    private func makeService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: database.quranDataService)
    }

    private func makeHighlightSUT(
        color: HighlightColor,
        service: MobileSyncAyahHighlightService? = nil,
        navigateToAyah: @escaping (AyahNumber) -> Void = { _ in }
    ) -> AyahSetViewModel {
        let service = service ?? makeHighlightService()
        return AyahSetViewModel(
            dataSource: HighlightAyahSetDataSource(
                color: color,
                initialAyahs: [],
                service: service
            ),
            quranTextDataService: makeQuranTextDataService(),
            navigateToAyah: navigateToAyah,
            dataSourceDeleted: {}
        )
    }

    private func makeHighlightService() -> MobileSyncAyahHighlightService {
        MobileSyncAyahHighlightService(quranDataService: database.quranDataService)
    }

    private func makeQuranTextDataService() -> QuranTextDataService {
        QuranTextDataService(
            databasesURL: URL(fileURLWithPath: "/tmp/unavailable-translations-database"),
            quranFileURL: QuranResources.quranUthmaniV2Database
        )
    }

    private func storedCollections(
        where predicate: ([CollectionWithAyahBookmarks]) -> Bool = { _ in true }
    ) async throws -> [CollectionWithAyahBookmarks] {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        while let collections = try await iterator.next() {
            if predicate(collections) {
                return collections
            }
        }
        throw TestError.expectedDatabaseStateNotObserved
    }

    private func firstCollection() async throws -> AyahBookmarkCollection {
        let stored = try await storedCollections {
            $0.contains { !$0.collection.isDefault }
        }
        return try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405)
                .first { !$0.collection.isDefault }
        )
    }

    private func storedHighlights(
        using service: MobileSyncAyahHighlightService,
        where predicate: ([AyahNumber: HighlightColor]) -> Bool
    ) async throws -> [AyahNumber: HighlightColor] {
        var iterator = service.highlightsSequence().makeAsyncIterator()
        while let highlights = try await iterator.next() {
            if predicate(highlights) {
                return highlights
            }
        }
        throw TestError.expectedDatabaseStateNotObserved
    }
}

private enum TestError: Error {
    case expectedDatabaseStateNotObserved
}
#endif

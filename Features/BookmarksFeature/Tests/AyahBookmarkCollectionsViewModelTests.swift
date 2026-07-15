#if QURAN_SYNC
import Combine
import MobileSync
import MobileSyncTestSupport
import QuranKit
import QuranResources
import QuranTextKit
import XCTest
@testable import BookmarksFeature

@MainActor
final class AyahBookmarkCollectionsViewModelTests: XCTestCase {
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
        let observation = sut.$collection
            .filter { $0.collection.name == "Favorites" }
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
            .filter { $0[ayah]?.isEmpty == false }
            .prefix(1)
            .sink { _ in retrieved.fulfill() }

        let task = Task { await sut.start() }
        await fulfillment(of: [retrieved], timeout: 2)

        XCTAssertFalse(try XCTUnwrap(sut.ayahTexts[ayah]).isEmpty)
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

        await sut.deleteBookmark(bookmark)

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
        sut.pendingCollectionName = " Duas "

        await sut.renamePendingCollection()

        let renamedCollection = try await firstCollection()
        XCTAssertEqual(renamedCollection.collection.name, "Duas")
        XCTAssertNil(sut.error)
    }

    func test_deleteCollection_removesCollectionAndNotifiesListener() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let collection = try await firstCollection()
        var didDeleteCollection = false
        let sut = makeSUT(
            collection: collection,
            service: service,
            collectionDeleted: { didDeleteCollection = true }
        )

        await sut.deleteCollection()

        let stored = try await storedCollections {
            $0.count == 1 && $0[0].collection.isDefault
        }
        XCTAssertEqual(stored.map(\.collection.name), ["Default"])
        XCTAssertTrue(stored[0].collection.isDefault)
        XCTAssertTrue(didDeleteCollection)
        XCTAssertNil(sut.error)
    }

    func test_highlightCollectionCannotBeRenamedOrDeleted() async throws {
        let service = makeService()
        try await service.createCollection(named: "Red")
        let collection = try await firstCollection()
        var didDeleteCollection = false
        let sut = makeSUT(
            collection: collection,
            service: service,
            collectionDeleted: { didDeleteCollection = true }
        )
        sut.pendingCollectionName = "Renamed"

        await sut.renamePendingCollection()
        await sut.deleteCollection()

        let storedCollection = try await firstCollection()
        XCTAssertEqual(storedCollection.collection.name, "Red")
        XCTAssertFalse(didDeleteCollection)
        XCTAssertNil(sut.error)
    }

    private func makeSUT(
        collection: AyahBookmarkCollection,
        service: AyahBookmarkCollectionService? = nil,
        quranTextDataService: QuranTextDataService? = nil,
        collectionDeleted: @escaping () -> Void = {}
    ) -> AyahBookmarkCollectionsViewModel {
        AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: service ?? makeService(),
            collection: collection,
            quranTextDataService: quranTextDataService ?? makeQuranTextDataService(),
            navigateToPage: { _ in },
            collectionDeleted: collectionDeleted
        )
    }

    private func makeService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: database.quranDataService)
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
}

private enum TestError: Error {
    case expectedDatabaseStateNotObserved
}
#endif

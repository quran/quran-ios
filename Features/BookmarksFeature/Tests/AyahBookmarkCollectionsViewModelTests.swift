#if QURAN_SYNC
import Combine
import MobileSync
import MobileSyncTestSupport
import QuranKit
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
        let sut = makeSUT(collectionID: collection.collection.id, service: service)
        let observed = expectation(description: "Observes persisted collection")
        let observation = sut.$collection.sink { collection in
            if collection?.collection.name == "Favorites" {
                observed.fulfill()
            }
        }

        let task = Task { await sut.start() }
        await fulfillment(of: [observed], timeout: 2)

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
        let sut = makeSUT(collectionID: collection.collection.id, service: service)

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

    private func makeSUT(
        collectionID: String,
        service: AyahBookmarkCollectionService? = nil
    ) -> AyahBookmarkCollectionsViewModel {
        AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: service ?? makeService(),
            collectionID: collectionID,
            navigateToPage: { _ in }
        )
    }

    private func makeService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: database.quranDataService)
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
}

private enum TestError: Error {
    case expectedDatabaseStateNotObserved
}
#endif

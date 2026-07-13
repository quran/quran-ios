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
        let stored = try await storedCollections()
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405).first
        )
        let sut = makeSUT(collectionLocalID: collection.collection.localId, service: service)
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

    private func makeSUT(
        collectionLocalID: String,
        service: AyahBookmarkCollectionService? = nil
    ) -> AyahBookmarkCollectionsViewModel {
        AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: service ?? makeService(),
            collectionLocalID: collectionLocalID,
            navigateToPage: { _ in }
        )
    }

    private func makeService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: database.quranDataService)
    }

    private func storedCollections() async throws -> [CollectionWithAyahBookmarks] {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        return try await iterator.next() ?? []
    }
}
#endif

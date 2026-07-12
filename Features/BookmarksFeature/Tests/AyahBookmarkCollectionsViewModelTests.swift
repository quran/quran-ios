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

    func test_sorted_groupsHighlightCollectionsBeforeUserCollections() {
        let collections = AyahBookmarkCollectionsViewModel.sorted([
            collection(name: "Z Collection"),
            collection(name: "blue"),
            collection(name: "A Collection"),
            collection(name: "red"),
        ])

        XCTAssertEqual(collections.map(\.collection.name), [
            "blue",
            "red",
            "A Collection",
            "Z Collection",
        ])
    }

    func test_createCollection_persistsThroughRealMobileSyncDatabase() async throws {
        let sut = makeSUT()

        await sut.createCollection(name: "Favorites")

        let collections = try await storedCollections()
        XCTAssertEqual(collections.map(\.collection.name), ["Favorites"])
        XCTAssertNil(sut.error)
    }

    func test_deleteCollection_removesFromRealMobileSyncDatabase() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let stored = try await storedCollections()
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405).first
        )
        let sut = makeSUT(service: service)

        await sut.deleteCollection(collection)

        let collections = try await storedCollections()
        XCTAssertTrue(collections.isEmpty)
        XCTAssertNil(sut.error)
    }

    func test_start_observesCollectionsFromMobileSyncDatabase() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let sut = makeSUT(service: service)
        let observed = expectation(description: "Observes persisted collection")
        let observation = sut.$collections.sink { collections in
            if collections.contains(where: { $0.collection.name == "Favorites" }) {
                observed.fulfill()
            }
        }

        let task = Task { await sut.start() }
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertNil(sut.error)
        task.cancel()
        observation.cancel()
    }

    private func makeSUT(service: AyahBookmarkCollectionService? = nil) -> AyahBookmarkCollectionsViewModel {
        AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: service ?? makeService(),
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

    private func collection(name: String) -> AyahBookmarkCollection {
        AyahBookmarkCollection(
            collection: Collection_(
                name: name,
                lastUpdated: .distantPast,
                localId: name
            ),
            bookmarks: []
        )
    }
}
#endif

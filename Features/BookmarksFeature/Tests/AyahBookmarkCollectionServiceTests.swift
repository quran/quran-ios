#if QURAN_SYNC
import MobileSync
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import BookmarksFeature

final class AyahBookmarkCollectionServiceTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private var service: AyahBookmarkCollectionService!

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        service = AyahBookmarkCollectionService(quranDataService: database.quranDataService)
    }

    override func tearDown() async throws {
        try await database.reset()
        service = nil
        try await super.tearDown()
    }

    func test_createCollection_persistsCollection() async throws {
        try await service.createCollection(named: "Favorites")

        let collections = try await storedCollections { collections in
            collections.contains { $0.collection.name == "Favorites" }
        }
        XCTAssertEqual(collections.map(\.collection.name), ["Favorites"])
    }

    func test_removeCollection_deletesPersistedCollection() async throws {
        try await service.createCollection(named: "Favorites")
        let collection = try await storedCollection(named: "Favorites")

        try await service.removeCollection(localId: collection.collection.localId)

        let collections = try await storedCollections { $0.isEmpty }
        XCTAssertTrue(collections.isEmpty)
    }

    func test_addAndRemoveAyahBookmark_persistsCollectionMembership() async throws {
        try await service.createCollection(named: "Favorites")
        let collection = try await storedCollection(named: "Favorites")

        try await service.addAyahBookmarkToCollection(
            collectionLocalId: collection.collection.localId,
            ayah: ayah(1)
        )

        let stored = try await storedCollection(named: "Favorites") { $0.bookmarks.count == 1 }
        XCTAssertEqual(stored.bookmarks.first?.sura, 1)
        XCTAssertEqual(stored.bookmarks.first?.ayah, 1)

        let bookmark = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: [stored], quran: .hafsMadani1405)
                .first?.bookmarks.first
        )
        try await service.removeBookmarkFromCollection(bookmark)

        let emptied = try await storedCollection(named: "Favorites") { $0.bookmarks.isEmpty }
        XCTAssertTrue(emptied.bookmarks.isEmpty)
    }

    func test_addAyahBookmarksIfNeeded_persistsOnlyMissingUniqueAyahs() async throws {
        try await service.createCollection(named: "Favorites")
        let stored = try await storedCollection(named: "Favorites")
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: [stored], quran: .hafsMadani1405).first
        )

        try await service.addAyahBookmarksIfNeeded([ayah(1), ayah(1), ayah(2)], to: collection)

        let updated = try await storedCollection(named: "Favorites") { $0.bookmarks.count == 2 }
        XCTAssertEqual(Set(updated.bookmarks.map { "\($0.sura):\($0.ayah)" }), ["1:1", "1:2"])
    }

    func test_collectionsSequence_createsAllMissingHighlightCollectionsInDatabase() async throws {
        var iterator = service.collectionsSequence().makeAsyncIterator()
        let expectedNames = Set(HighlightColor.sortedColors.map(\.collectionName))

        let collections = try await nextCollections(from: &iterator) { collections in
            expectedNames.isSubset(of: Set(collections.map(\.collection.name)))
        }

        XCTAssertTrue(expectedNames.isSubset(of: Set(collections.map(\.collection.name))))
    }

    private func storedCollection(
        named name: String,
        where predicate: (CollectionWithAyahBookmarks) -> Bool = { _ in true }
    ) async throws -> CollectionWithAyahBookmarks {
        let collections = try await storedCollections { collections in
            collections.contains { $0.collection.name == name && predicate($0) }
        }
        return try XCTUnwrap(collections.first { $0.collection.name == name })
    }

    private func storedCollections(
        where predicate: ([CollectionWithAyahBookmarks]) -> Bool
    ) async throws -> [CollectionWithAyahBookmarks] {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        while let collections = try await iterator.next() {
            if predicate(collections) {
                return collections
            }
        }
        throw TestError.expectedDatabaseStateNotObserved
    }

    private func nextCollections(
        from iterator: inout AyahBookmarkCollectionsSequence.AsyncIterator,
        where predicate: ([AyahBookmarkCollection]) -> Bool
    ) async throws -> [AyahBookmarkCollection] {
        while let collections = try await iterator.next() {
            if predicate(collections) {
                return collections
            }
        }
        throw TestError.expectedDatabaseStateNotObserved
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: number)!
    }
}

private enum TestError: Error {
    case expectedDatabaseStateNotObserved
}
#endif

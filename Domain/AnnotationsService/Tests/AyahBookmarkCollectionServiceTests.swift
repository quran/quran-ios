#if QURAN_SYNC
import MobileSync
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import AnnotationsService

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
        try await service.createCollection(named: "Personal")

        let collections = try await storedCollections { collections in
            collections.contains { $0.collection.name == "Personal" }
        }
        XCTAssertEqual(collections.count, 2)
        XCTAssertTrue(collections.contains { $0.collection.isDefault })
        XCTAssertTrue(collections.contains { $0.collection.name == "Personal" })
    }

    func test_removeCollection_deletesPersistedCollection() async throws {
        try await service.createCollection(named: "Personal")
        let collection = try await storedCollection(named: "Personal")

        try await service.removeCollection(id: collection.collection.id)

        let collections = try await storedCollections {
            $0.count == 1 && $0.first?.collection.isDefault == true
        }
        XCTAssertTrue(collections[0].collection.isDefault)
    }

    func test_addAndRemoveAyahBookmark_persistsCollectionMembership() async throws {
        try await service.createCollection(named: "Personal")
        let collection = try await storedCollection(named: "Personal")

        try await service.addAyahBookmarkToCollection(
            collectionId: collection.collection.id,
            ayah: ayah(1)
        )

        let stored = try await storedCollection(named: "Personal") { $0.bookmarks.count == 1 }
        XCTAssertEqual(stored.bookmarks.first?.sura, 1)
        XCTAssertEqual(stored.bookmarks.first?.ayah, 1)

        let bookmark = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: [stored], quran: .hafsMadani1405)
                .first?.bookmarks.first
        )
        try await service.removeBookmarkFromCollection(bookmark)

        let emptied = try await storedCollection(named: "Personal") { $0.bookmarks.isEmpty }
        XCTAssertTrue(emptied.bookmarks.isEmpty)
    }

    func test_addAyahs_persistsOnlyMissingUniqueAyahs() async throws {
        try await service.createCollection(named: "Personal")
        let stored = try await storedCollection(named: "Personal")

        try await service.addAyahs(
            [ayah(1), ayah(1), ayah(2)],
            toCollectionWithID: stored.collection.id
        )

        let updated = try await storedCollection(named: "Personal") { $0.bookmarks.count == 2 }
        XCTAssertEqual(Set(updated.bookmarks.map { "\($0.sura):\($0.ayah)" }), ["1:1", "1:2"])
    }

    func test_removeAyahs_removesOnlyRequestedCollectionMemberships() async throws {
        try await service.createCollection(named: "Personal")
        try await service.createCollection(named: "Study")
        let personal = try await storedCollection(named: "Personal")
        let study = try await storedCollection(named: "Study")
        for number in [1, 2] {
            try await service.addAyahBookmarkToCollection(collectionId: personal.collection.id, ayah: ayah(number))
            try await service.addAyahBookmarkToCollection(collectionId: study.collection.id, ayah: ayah(number))
        }

        try await service.removeAyahs([ayah(1)], fromCollectionWithID: personal.collection.id)

        let updatedPersonal = try await storedCollection(named: "Personal") { $0.bookmarks.count == 1 }
        let updatedStudy = try await storedCollection(named: "Study") { $0.bookmarks.count == 2 }
        XCTAssertEqual(updatedPersonal.bookmarks.map(\.ayah), [2])
        XCTAssertEqual(Set(updatedStudy.bookmarks.map(\.ayah)), [1, 2])
    }

    func test_collectionsSequence_excludesSystemHighlightCollections() async throws {
        let highlightService = MobileSyncAyahHighlightService(quranDataService: database.quranDataService)
        try await highlightService.setHighlight(.purple, for: [ayah(1)])
        var iterator = service.collectionsSequence().makeAsyncIterator()

        let collections = try await iterator.next() ?? []

        XCTAssertEqual(collections.count, 1)
        XCTAssertTrue(collections[0].isDefault)
    }

    func test_collectionsSequence_marksFavoritesReadOnly() async throws {
        var iterator = service.collectionsSequence().makeAsyncIterator()

        let collections = try await iterator.next() ?? []

        let favorites = try XCTUnwrap(collections.first { $0.isDefault })
        XCTAssertTrue(favorites.isReadOnly)
        XCTAssertFalse(favorites.canRename)
        XCTAssertFalse(favorites.canDelete)
    }

    func test_collections_keepsReadOnlyCollectionsFromOlderApps() {
        let collections = AyahBookmarkCollectionService.collections(
            from: [
                collectionWithBookmarks(id: "1", name: "Green", isReadOnly: true),
                collectionWithBookmarks(id: "2", name: "Personal", isReadOnly: false),
            ],
            quran: .hafsMadani1405
        )

        XCTAssertEqual(collections.map(\.name), ["Green", "Personal"])
        XCTAssertEqual(collections.map(\.canRename), [false, true])
        XCTAssertEqual(collections.map(\.canDelete), [false, true])
    }

    func test_createCollection_throwsTextLengthLimitErrorForBlankName() async {
        await assertThrows(TextLengthLimitError(field: .collectionName, bound: .tooShort, limit: 1)) {
            try await service.createCollection(named: "   ")
        }
    }

    func test_renameCollection_throwsTextLengthLimitErrorAndKeepsName() async throws {
        try await service.createCollection(named: "Personal")
        let collection = try await storedCollection(named: "Personal")

        await assertThrows(TextLengthLimitError(field: .collectionName, bound: .tooLong, limit: 255)) {
            try await service.renameCollection(id: collection.collection.id, to: String(repeating: "a", count: 256))
        }

        let stored = try await storedCollection(named: "Personal")
        XCTAssertEqual(stored.collection.id, collection.collection.id)
    }

    func test_renameCollection_throwsDuplicateCollectionNameErrorAndKeepsName() async throws {
        try await service.createCollection(named: "Study")
        try await service.createCollection(named: "Personal")
        let collection = try await storedCollection(named: "Personal")

        await assertThrows(DuplicateCollectionNameError(name: "Study")) {
            try await service.renameCollection(id: collection.collection.id, to: " study ")
        }

        let stored = try await storedCollection(named: "Personal")
        XCTAssertEqual(stored.collection.id, collection.collection.id)
    }

    func test_renameAndRemoveFavorites_throwReadOnlyCollectionError() async throws {
        var iterator = service.collectionsSequence().makeAsyncIterator()
        let collections = try await iterator.next() ?? []
        let favorites = try XCTUnwrap(collections.first { $0.isDefault })
        let expected = ReadOnlyCollectionError(collectionID: favorites.id)

        await assertThrows(expected) {
            try await service.renameCollection(id: favorites.id, to: "Renamed")
        }
        await assertThrows(expected) {
            try await service.removeCollection(id: favorites.id)
        }

        let stored = try await storedCollections { $0.contains { $0.collection.isDefault } }
        XCTAssertEqual(stored.first { $0.collection.isDefault }?.collection.id, favorites.id)
    }

    private func collectionWithBookmarks(id: String, name: String, isReadOnly: Bool) -> CollectionWithAyahBookmarks {
        CollectionWithAyahBookmarks(
            collection: BookmarkCollection(
                name: name,
                lastUpdated: Date(timeIntervalSince1970: 0),
                id: id,
                isDefault: false,
                isSystem: false,
                isReadOnly: isReadOnly
            ),
            bookmarks: []
        )
    }

    private func assertThrows<E: Error & Equatable>(
        _ expected: E,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? E, expected, file: file, line: line)
        }
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

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: number)!
    }
}

private enum TestError: Error {
    case expectedDatabaseStateNotObserved
}
#endif

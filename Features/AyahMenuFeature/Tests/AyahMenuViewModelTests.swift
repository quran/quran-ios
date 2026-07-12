#if QURAN_SYNC
import MobileSync
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit
import XCTest
@testable import AyahMenuFeature
@testable import BookmarksFeature

@MainActor
final class AyahMenuViewModelTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    func test_updateHighlight_movesAyahBetweenCollectionsInMobileSyncDatabase() async throws {
        let service = AyahBookmarkCollectionService(quranDataService: database.quranDataService)
        try await service.createCollection(named: HighlightColor.red.collectionName)
        try await service.createCollection(named: HighlightColor.blue.collectionName)
        let collections = try await storedCollections()
        let mapped = AyahBookmarkCollectionService.collections(from: collections, quran: .hafsMadani1405)
        let red = try XCTUnwrap(mapped.first { $0.collection.name == HighlightColor.red.collectionName })
        try await service.addAyahBookmarkToCollection(
            collectionLocalId: red.collection.localId,
            ayah: ayah
        )
        let populatedCollections = AyahBookmarkCollectionService.collections(
            from: try await storedCollections(),
            quran: .hafsMadani1405
        )
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        let sut = AyahMenuViewModel(deps: .init(
            sourceView: UIView(),
            pointInView: .zero,
            verses: [ayah],
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            notes: [],
            highlightVerses: [ayah: .red],
            highlightCollections: populatedCollections,
            ayahBookmarkCollectionService: service
        ))

        await sut.updateHighlight(color: .blue)

        let updated = try await storedCollections()
        let redBookmarks = updated.first { $0.collection.name == HighlightColor.red.collectionName }?.bookmarks
        let blueBookmarks = updated.first { $0.collection.name == HighlightColor.blue.collectionName }?.bookmarks
        XCTAssertTrue(redBookmarks?.isEmpty == true)
        XCTAssertEqual(blueBookmarks?.count, 1)
        XCTAssertEqual(blueBookmarks?.first?.sura, 1)
        XCTAssertEqual(blueBookmarks?.first?.ayah, 1)
    }

    private var ayah: AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
    }

    private func storedCollections() async throws -> [CollectionWithAyahBookmarks] {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        return try await iterator.next() ?? []
    }
}
#endif

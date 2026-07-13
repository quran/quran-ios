#if QURAN_SYNC
import AnnotationsService
import Combine
import MobileSync
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import BookmarksFeature
@testable import QuranViewFeature

@MainActor
final class QuranSyncedHighlightsObserverTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    func test_start_appliesPersistedMobileSyncBookmarksToHighlights() async throws {
        let collectionService = AyahBookmarkCollectionService(quranDataService: database.quranDataService)
        try await collectionService.createCollection(named: HighlightColor.green.collectionName.uppercased())
        let stored = try await storedCollections()
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(
                from: stored,
                quran: .hafsMadani1405
            ).first
        )
        try await collectionService.addAyahBookmarkToCollection(
            collectionLocalId: collection.collection.localId,
            ayah: ayah
        )
        let highlightsService = QuranHighlightsService()
        let observer = QuranSyncedHighlightsObserver(
            ayahBookmarkCollectionService: collectionService,
            highlightsService: highlightsService
        )
        let applied = expectation(description: "Applies persisted synced highlight")
        let observation = highlightsService.$highlights.sink { [ayah] highlights in
            if highlights.highlightVerses[ayah] == .green {
                applied.fulfill()
            }
        }

        observer.start()
        await fulfillment(of: [applied], timeout: 2)

        XCTAssertEqual(highlightsService.highlights.highlightVerses[ayah], .green)
        XCTAssertEqual(observer.collections.first?.bookmarks.first?.ayah, ayah)
        observation.cancel()
        withExtendedLifetime(observer) {}
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

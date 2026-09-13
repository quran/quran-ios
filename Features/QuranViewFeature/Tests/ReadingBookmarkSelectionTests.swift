#if QURAN_SYNC
import AnnotationsService
import Combine
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import QuranViewFeature

@MainActor
final class ReadingBookmarkSelectionTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        service = MobileSyncReadingBookmarkService(quranDataService: database.quranDataService)
        observer = QuranAnnotationsObserver(
            noteService: MobileSyncNoteService(quranDataService: database.quranDataService),
            highlightService: MobileSyncAyahHighlightService(quranDataService: database.quranDataService),
            collectionService: AyahBookmarkCollectionService(quranDataService: database.quranDataService),
            readingBookmarkService: service,
            quran: .hafsMadani1405,
            highlightsService: QuranHighlightsService()
        )
    }

    override func tearDown() async throws {
        observer.stop()
        observer = nil
        service = nil
        try await database.reset()
        try await super.tearDown()
    }

    func test_latest_returnsMostRecentlyModifiedBookmarkAtLocation() async throws {
        let page = Quran.hafsMadani1405.pages[2]
        let older = try await bookmark(slot: .teal, placement: .page(page))
        let newer = try await bookmark(slot: .coral, placement: .page(page))
        let unrelated = try await bookmark(slot: .indigo, placement: .page(Quran.hafsMadani1405.pages[3]))
        await observeBookmarks(count: 3)

        XCTAssertGreaterThan(newer.modifiedOn, older.modifiedOn)
        XCTAssertGreaterThan(unrelated.modifiedOn, newer.modifiedOn)
        XCTAssertEqual(observer.latestReadingBookmark(at: [.page(page)]), newer)
    }

    func test_latest_returnsNilWithoutBookmarkAtLocation() async throws {
        let page = Quran.hafsMadani1405.pages[2]
        try await bookmark(slot: .coral, placement: .page(Quran.hafsMadani1405.pages[3]))
        await observeBookmarks(count: 1)

        XCTAssertNil(observer.latestReadingBookmark(at: [.page(page)]))
    }

    func test_latest_returnsMostRecentlyModifiedBookmarkAcrossLocations() async throws {
        let firstPage = Quran.hafsMadani1405.pages[2]
        let secondPage = Quran.hafsMadani1405.pages[3]
        let older = try await bookmark(slot: .teal, placement: .page(firstPage))
        let newer = try await bookmark(slot: .coral, placement: .page(secondPage))
        let unrelated = try await bookmark(slot: .indigo, placement: .page(Quran.hafsMadani1405.pages[4]))
        await observeBookmarks(count: 3)

        XCTAssertGreaterThan(newer.modifiedOn, older.modifiedOn)
        XCTAssertGreaterThan(unrelated.modifiedOn, newer.modifiedOn)
        XCTAssertEqual(observer.latestReadingBookmark(at: [.page(firstPage), .page(secondPage)]), newer)
    }

    func test_latest_returnsNilWithoutRequestedPlacements() async throws {
        try await bookmark(slot: .teal, placement: .page(Quran.hafsMadani1405.pages[2]))
        await observeBookmarks(count: 1)

        XCTAssertNil(observer.latestReadingBookmark(at: []))
    }

    private let database = MobileSyncTestDatabase.shared
    private var service: MobileSyncReadingBookmarkService!
    private var observer: QuranAnnotationsObserver!

    @discardableResult
    private func bookmark(
        slot: ReadingBookmarkSlot,
        placement: PlacedReadingBookmark.Placement
    ) async throws -> PlacedReadingBookmark {
        // The persistence service timestamps writes in milliseconds; separate the writes to avoid ties.
        try await Task.sleep(nanoseconds: 10_000_000)
        return try await service.addReadingBookmark(at: placement, slot: slot)
    }

    private func observeBookmarks(count: Int) async {
        let observed = expectation(description: "Observes persisted reading bookmarks")
        let observation = observer.$readingBookmarks.first { $0.count == count }
            .sink { _ in observed.fulfill() }
        defer { observation.cancel() }
        observer.start()
        await fulfillment(of: [observed], timeout: 2)
    }
}
#endif

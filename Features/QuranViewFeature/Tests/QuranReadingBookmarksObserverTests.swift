#if QURAN_SYNC
import AnnotationsService
import Combine
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import QuranViewFeature

@MainActor
final class QuranReadingBookmarksObserverTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private var service: MobileSyncReadingBookmarkService!

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        service = MobileSyncReadingBookmarkService(quranDataService: database.quranDataService)
    }

    override func tearDown() async throws {
        try await database.reset()
        service = nil
        try await super.tearDown()
    }

    func test_start_publishesPersistedBookmarks() async throws {
        let page = Quran.hafsMadani1405.pages[40]
        try await service.addReadingBookmark(at: .page(page), slot: .coral)
        let sut = QuranReadingBookmarksObserver(service: service, quran: .hafsMadani1405)
        let observed = expectation(description: "Publishes persisted reading bookmark")
        let observation = sut.$bookmarks.sink { bookmarks in
            if bookmarks.map(\.slot) == [.coral] {
                observed.fulfill()
            }
        }

        sut.start()
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertEqual(sut.bookmarks.map(\.slot), [.coral])
        observation.cancel()
        withExtendedLifetime(sut) {}
    }

    func test_start_publishesSubsequentBookmarkChanges() async throws {
        let sut = QuranReadingBookmarksObserver(service: service, quran: .hafsMadani1405)
        let observed = expectation(description: "Publishes subsequent reading bookmark")
        let observation = sut.$bookmarks.sink { bookmarks in
            if bookmarks.map(\.slot) == [.teal] {
                observed.fulfill()
            }
        }

        sut.start()
        try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .teal)
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertEqual(sut.bookmarks.map(\.slot), [.teal])
        observation.cancel()
        withExtendedLifetime(sut) {}
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: number)!
    }
}
#endif

#if QURAN_SYNC
import Combine
import MobileSyncTestSupport
import QuranKit
import XCTest
@testable import AnnotationsService

final class MobileSyncLastPageServiceTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private var service: MobileSyncLastPageService!

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        service = MobileSyncLastPageService(quranDataService: database.quranDataService)
    }

    override func tearDown() async throws {
        try await database.reset()
        service = nil
        try await super.tearDown()
    }

    func test_add_persistsReadingSessionAndPublishesLastPage() async throws {
        let quran = Quran.hafsMadani1405
        let page = quran.pages[10]
        let published = expectation(description: "Publishes the persisted last page")
        let cancellable = service.lastPages(quran: quran).sink { lastPages in
            if lastPages.first?.page == page {
                published.fulfill()
            }
        }

        let lastPage = try await service.add(page: page)

        XCTAssertEqual(lastPage.page, page)
        XCTAssertNotNil(lastPage.localId)
        await fulfillment(of: [published], timeout: 2)
        cancellable.cancel()
    }

    func test_update_persistsNewPageOnExistingReadingSession() async throws {
        let quran = Quran.hafsMadani1405
        let original = try await service.add(page: quran.pages[10])

        let updated = try await service.update(lastPage: original, toPage: quran.pages[20])

        XCTAssertEqual(updated.localId, original.localId)
        XCTAssertEqual(updated.page, quran.pages[20])
        let sessions = database.quranDataService.readingSessionsSequence().makeAsyncIterator()
        let storedSessions = try await sessions.next()
        XCTAssertEqual(storedSessions?.count, 1)
        XCTAssertEqual(storedSessions?.first?.id, original.localId)
        XCTAssertEqual(storedSessions?.first?.sura, Int32(quran.pages[20].firstVerse.sura.suraNumber))
        XCTAssertEqual(storedSessions?.first?.ayah, Int32(quran.pages[20].firstVerse.ayah))
    }
}
#endif

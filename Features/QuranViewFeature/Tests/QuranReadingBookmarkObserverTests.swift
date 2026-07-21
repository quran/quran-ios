#if QURAN_SYNC
import AnnotationsService
import Combine
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import QuranViewFeature

@MainActor
final class QuranReadingBookmarkObserverTests: XCTestCase {
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

    func test_start_publishesPersistedPageBookmark() async throws {
        let page = Quran.hafsMadani1405.pages[40]
        try await service.addReadingBookmark(at: .page(page))
        let sut = QuranReadingBookmarkObserver(service: service, quran: .hafsMadani1405)
        let observed = expectation(description: "Publishes persisted page bookmark")
        let observation = sut.$bookmark.sink { bookmark in
            if bookmark?.location == .page(page) {
                observed.fulfill()
            }
        }

        sut.start()
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertEqual(sut.bookmark?.location, .page(page))
        observation.cancel()
        withExtendedLifetime(sut) {}
    }

    func test_addAndRemove_publishLocalPageBookmarkChanges() async throws {
        let page = Quran.hafsMadani1405.pages[40]
        let sut = QuranReadingBookmarkObserver(service: service, quran: .hafsMadani1405)
        var observedLocations: [ReadingPositionBookmark.Location?] = []
        let observation = sut.$bookmark.sink { observedLocations.append($0?.location) }

        let added = try await sut.add(at: .page(page))
        let removed = try await sut.remove()

        XCTAssertEqual(added.location, .page(page))
        XCTAssertEqual(removed?.location, .page(page))
        XCTAssertEqual(observedLocations, [nil, .page(page), nil])
        observation.cancel()
    }
}
#endif

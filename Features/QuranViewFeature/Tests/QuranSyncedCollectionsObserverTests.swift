#if QURAN_SYNC
import AnnotationsService
import MobileSyncTestSupport
import QuranKit
import XCTest
@testable import QuranViewFeature

@MainActor
final class QuranSyncedCollectionsObserverTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    func test_start_observesBookmarkCollectionsSeparatelyFromHighlights() async throws {
        let service = AyahBookmarkCollectionService(quranDataService: database.quranDataService)
        try await service.createCollection(named: "Duas")
        let observer = QuranSyncedCollectionsObserver(service: service)

        observer.start()
        for _ in 0 ..< 1000 where !observer.collections.contains(where: { $0.collection.name == "Duas" }) {
            await Task.yield()
        }

        XCTAssertEqual(observer.collections.count, 2)
        XCTAssertTrue(observer.collections.contains { $0.collection.isDefault })
        XCTAssertTrue(observer.collections.contains { $0.collection.name == "Duas" })
        withExtendedLifetime(observer) {}
    }
}
#endif

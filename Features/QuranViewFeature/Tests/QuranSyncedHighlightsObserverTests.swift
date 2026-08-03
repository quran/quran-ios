#if QURAN_SYNC
import AnnotationsService
import Combine
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

    func test_start_appliesPersistedMobileSyncHighlights() async throws {
        let highlightService = MobileSyncAyahHighlightService(quranDataService: database.quranDataService)
        try await highlightService.setHighlight(.green, for: [ayah])
        let highlightsService = QuranHighlightsService()
        let observer = QuranSyncedHighlightsObserver(
            ayahHighlightService: highlightService,
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
        observation.cancel()
        withExtendedLifetime(observer) {}
    }

    private var ayah: AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
    }
}
#endif

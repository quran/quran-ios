import AnnotationsService
import QuranKit
import XCTest
@testable import AppStructureFeature
#if QURAN_SYNC
import MobileSyncTestSupport
#else
import CoreDataPersistenceTestSupport
import LastPagePersistence
#endif

@MainActor
final class ReadingContinuationTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        #if QURAN_SYNC
        try await database.reset()
        service = MobileSyncLastPageService(quranDataService: database.quranDataService)
        #else
        store = TemporaryCoreDataStore()
        service = PersistenceLastPageService(persistence: CoreDataLastPagePersistence(stack: store.stack()))
        #endif
    }

    override func tearDown() async throws {
        service = nil
        #if QURAN_SYNC
        try await database.reset()
        #else
        store = nil
        #endif
        try await super.tearDown()
    }

    func testFreshHistoryStartsAtSelectedQuransFirstReadablePage() async throws {
        let continuation = try await ReadingContinuation.resolve(quran: .hafsIndoPak, service: service)

        XCTAssertEqual(continuation.page.pageNumber, 2)
        XCTAssertEqual(continuation.page.quran, .hafsIndoPak)
        XCTAssertNil(continuation.lastPage)
    }

    func testContinuationPreservesMostRecentSessionIdentity() async throws {
        let quran = Quran.hafsMadani1405
        let older = try await service.add(page: quran.pages[10])
        _ = try await service.add(page: quran.pages[20])
        let latest = try await service.update(lastPage: older, toPage: quran.pages[30])

        let continuation = try await ReadingContinuation.resolve(quran: quran, service: service)

        XCTAssertEqual(continuation.page, latest.page)
        XCTAssertEqual(continuation.lastPage, latest)
    }

    func testContinuationMapsHistoryIntoSelectedQuran() async throws {
        let sourcePage = Quran.hafsMadani1405.pages[20]
        _ = try await service.add(page: sourcePage)

        let continuation = try await ReadingContinuation.resolve(quran: .hafsIndoPak, service: service)

        XCTAssertEqual(continuation.page.quran, .hafsIndoPak)
        #if QURAN_SYNC
        let sourceAyah = sourcePage.firstVerse
        let destinationAyah = try XCTUnwrap(AyahNumber(quran: .hafsIndoPak, sura: sourceAyah.sura.suraNumber, ayah: sourceAyah.ayah))
        XCTAssertEqual(continuation.page, destinationAyah.page)
        #else
        XCTAssertEqual(continuation.page, QuranPageMapper(destination: .hafsIndoPak).mapPage(sourcePage))
        #endif
        XCTAssertEqual(continuation.lastPage?.page, continuation.page)
    }

    private var service: (any LastPageService)!
    #if QURAN_SYNC
    private let database = MobileSyncTestDatabase.shared
    #else
    private var store: TemporaryCoreDataStore!
    #endif
}

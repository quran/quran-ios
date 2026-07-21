#if QURAN_SYNC
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import AnnotationsService

final class MobileSyncReadingBookmarkServiceTests: XCTestCase {
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

    func test_addReadingBookmark_persistsAyahLocation() async throws {
        let ayah = ayah(255)

        let created = try await service.addReadingBookmark(at: .ayah(ayah))
        let stored = try await storedBookmark()

        XCTAssertEqual(created.location, .ayah(ayah))
        XCTAssertEqual(stored?.location, .ayah(ayah))
    }

    func test_addReadingBookmark_replacesExistingBookmark() async throws {
        let original = ayah(254)
        let destination = ayah(255)
        try await service.addReadingBookmark(at: .ayah(original))

        try await service.addReadingBookmark(at: .ayah(destination))
        let stored = try await storedBookmark()

        XCTAssertEqual(stored?.location, .ayah(destination))
    }

    func test_removeReadingBookmark_deletesCurrentBookmark() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(255)))

        let removed = try await service.removeReadingBookmark()
        let stored = try await storedBookmark()

        XCTAssertTrue(removed)
        XCTAssertNil(stored)
    }

    func test_readingBookmarkSequence_mapsPageIntoRequestedQuran() async throws {
        let storedPage = Quran.hafsMadani1405.pages[254]
        _ = try await database.quranDataService.addPageReadingBookmark(page: Int32(storedPage.pageNumber))
        let quran = Quran.hafsNaskh
        let expectedPage = try XCTUnwrap(QuranPageMapper(destination: quran).mapPage(storedPage))

        let bookmark = try await storedBookmark(quran: quran)

        XCTAssertEqual(bookmark?.location, .page(expectedPage))
    }

    func test_addReadingBookmark_persistsPageLocation() async throws {
        let storedPage = Quran.hafsMadani1405.pages[254]

        let created = try await service.addReadingBookmark(at: .page(storedPage))
        let stored = try await storedBookmark()

        XCTAssertEqual(created.location, .page(storedPage))
        XCTAssertEqual(stored?.location, .page(storedPage))
    }

    private func storedBookmark(quran: Quran = .hafsMadani1405) async throws -> ReadingPositionBookmark? {
        var iterator = service.readingBookmarkSequence(quran: quran).makeAsyncIterator()
        guard let bookmark = try await iterator.next() else {
            XCTFail("Reading bookmark sequence ended unexpectedly")
            return nil
        }
        return bookmark
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: number)!
    }
}
#endif

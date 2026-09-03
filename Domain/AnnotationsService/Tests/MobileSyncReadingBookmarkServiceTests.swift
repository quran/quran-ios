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

        let created = try await service.addReadingBookmark(at: .ayah(ayah), slot: .coral)
        let stored = try await storedBookmark()

        XCTAssertEqual(created.location, .ayah(ayah))
        XCTAssertEqual(created.slot, .coral)
        XCTAssertEqual(stored?.location, .ayah(ayah))
    }

    func test_addReadingBookmark_replacesExistingBookmark() async throws {
        let original = ayah(254)
        let destination = ayah(255)
        try await service.addReadingBookmark(at: .ayah(original), slot: .teal)

        try await service.addReadingBookmark(at: .ayah(destination), slot: .teal)
        let stored = try await storedBookmark(in: .teal)

        XCTAssertEqual(stored?.location, .ayah(destination))
    }

    func test_removeReadingBookmark_deletesCurrentBookmark() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .indigo)

        try await service.removeReadingBookmark(in: .indigo)
        let stored = try await storedBookmark(in: .indigo)

        XCTAssertNil(stored)
    }

    func test_readingBookmarkSequence_mapsPageIntoRequestedQuran() async throws {
        let storedPage = Quran.hafsMadani1405.pages[254]
        _ = try await service.addReadingBookmark(at: .page(storedPage), slot: .coral)
        let quran = Quran.hafsIndoPak
        let expectedPage = try XCTUnwrap(QuranPageMapper(destination: quran).mapPage(storedPage))

        let bookmark = try await storedBookmark(quran: quran)

        XCTAssertEqual(bookmark?.location, .page(expectedPage))
    }

    func test_addReadingBookmark_persistsPageLocation() async throws {
        let storedPage = Quran.hafsMadani1405.pages[254]

        let created = try await service.addReadingBookmark(at: .page(storedPage), slot: .coral)
        let stored = try await storedBookmark()

        XCTAssertEqual(created.location, .page(storedPage))
        XCTAssertEqual(stored?.location, .page(storedPage))
    }

    func test_addReadingBookmarks_preservesEachSlot() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(254)), slot: .coral)
        try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .teal)

        let bookmarks = try await storedBookmarks()

        XCTAssertEqual(Set(bookmarks.map(\.slot)), [.coral, .teal])
    }

    func test_readingBookmarksSequence_ordersBookmarksBySlot() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(256)), slot: .indigo)
        try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .teal)
        try await service.addReadingBookmark(at: .ayah(ayah(254)), slot: .coral)

        let bookmarks = try await storedBookmarks()

        XCTAssertEqual(bookmarks.map(\.slot), [.coral, .teal, .indigo])
    }

    private func storedBookmark(
        in slot: ReadingBookmarkSlot = .coral,
        quran: Quran = .hafsMadani1405
    ) async throws -> ReadingPositionBookmark? {
        try await storedBookmarks(quran: quran).first { $0.slot == slot }
    }

    private func storedBookmarks(quran: Quran = .hafsMadani1405) async throws -> [ReadingPositionBookmark] {
        var iterator = service.readingBookmarksSequence(quran: quran).makeAsyncIterator()
        guard let bookmarks = try await iterator.next() else {
            XCTFail("Reading bookmark sequence ended unexpectedly")
            return []
        }
        return bookmarks
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: number)!
    }
}
#endif

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
        let placement = PlacedReadingBookmark.Placement.ayah(ayah)

        let created: PlacedReadingBookmark = try await service.addReadingBookmark(at: placement, slot: .coral)
        let stored = try await storedBookmark()

        XCTAssertEqual(created.placement, .ayah(ayah))
        XCTAssertEqual(created.slot, .coral)
        XCTAssertEqual(stored?.placement, .ayah(ayah))
        XCTAssertEqual(stored, ReadingBookmark(created))
    }

    func test_addReadingBookmark_replacesExistingBookmark() async throws {
        let original = ayah(254)
        let destination = ayah(255)
        try await service.addReadingBookmark(at: .ayah(original), slot: .teal)

        try await service.addReadingBookmark(at: .ayah(destination), slot: .teal)
        let stored = try await storedBookmark(in: .teal)

        XCTAssertEqual(stored?.placement, .ayah(destination))
    }

    func test_clearReadingBookmark_clearsLocationButPreservesPin() async throws {
        let placed = try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .indigo)

        let cleared = try await service.clearReadingBookmark(in: .indigo)
        let stored = try await storedBookmark(in: .indigo)

        XCTAssertEqual(stored, cleared)
        XCTAssertEqual(stored?.id, placed.id)
        XCTAssertEqual(stored?.slot, .indigo)
        XCTAssertEqual(stored?.placement, .unplaced)
    }

    func test_readingBookmarkSequence_mapsPageIntoRequestedQuran() async throws {
        let storedPage = Quran.hafsMadani1405.pages[254]
        _ = try await service.addReadingBookmark(at: .page(storedPage), slot: .coral)
        let quran = Quran.hafsIndoPak
        let expectedPage = try XCTUnwrap(QuranPageMapper(destination: quran).mapPage(storedPage))

        let bookmark = try await storedBookmark(quran: quran)

        XCTAssertEqual(bookmark?.placement, .page(expectedPage))
    }

    func test_addReadingBookmark_persistsPageLocation() async throws {
        let storedPage = Quran.hafsMadani1405.pages[254]

        let created = try await service.addReadingBookmark(at: .page(storedPage), slot: .coral)
        let stored = try await storedBookmark()

        XCTAssertEqual(created.placement, .page(storedPage))
        XCTAssertEqual(stored?.placement, .page(storedPage))
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

    func test_placedReadingBookmarksSequence_filtersUnplacedPinsAndPreservesMetadata() async throws {
        let indigo = try await service.addReadingBookmark(at: .ayah(ayah(256)), slot: .indigo)
        let coral = try await service.addReadingBookmark(at: .ayah(ayah(254)), slot: .coral)
        try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .teal)
        try await service.clearReadingBookmark(in: .teal)

        var iterator = service.placedReadingBookmarksSequence(quran: .hafsMadani1405).makeAsyncIterator()
        let placed = try await iterator.next()
        let all = try await storedBookmarks()

        XCTAssertEqual(all.map(\.slot), [.coral, .teal, .indigo])
        XCTAssertEqual(all.first { $0.slot == .teal }?.placement, .unplaced)
        XCTAssertEqual(placed, [
            PlacedReadingBookmark(
                id: coral.id, slot: .coral, placement: .ayah(ayah(254)),
                modifiedOn: coral.modifiedOn, name: coral.name
            ),
            PlacedReadingBookmark(
                id: indigo.id, slot: .indigo, placement: .ayah(ayah(256)),
                modifiedOn: indigo.modifiedOn, name: indigo.name
            ),
        ])
    }

    func test_placedReadingBookmarksSequence_mapsPageIntoRequestedQuran() async throws {
        let storedPage = Quran.hafsMadani1405.pages[254]
        try await service.addReadingBookmark(at: .page(storedPage), slot: .coral)
        let quran = Quran.hafsIndoPak
        let expectedPage = try XCTUnwrap(QuranPageMapper(destination: quran).mapPage(storedPage))

        var iterator = service.placedReadingBookmarksSequence(quran: quran).makeAsyncIterator()
        let placed = try await iterator.next()

        XCTAssertEqual(placed?.first?.placement, .page(expectedPage))
        XCTAssertEqual(placed?.first?.sura, expectedPage.firstVerse.sura)
    }

    private func storedBookmark(
        in slot: ReadingBookmarkSlot = .coral,
        quran: Quran = .hafsMadani1405
    ) async throws -> ReadingBookmark? {
        try await storedBookmarks(quran: quran).first { $0.slot == slot }
    }

    private func storedBookmarks(quran: Quran = .hafsMadani1405) async throws -> [ReadingBookmark] {
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

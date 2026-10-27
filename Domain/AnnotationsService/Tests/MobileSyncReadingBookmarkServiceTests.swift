#if QURAN_SYNC
import MobileSync
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

        let created: PlacedReadingBookmark = try await service.addReadingBookmark(at: placement, slot: .teal)
        let stored = try await storedBookmark()

        XCTAssertEqual(created.placement, .ayah(ayah))
        XCTAssertEqual(created.slot, .teal)
        XCTAssertEqual(stored?.placement, .ayah(ayah))
        XCTAssertEqual(stored, ReadingBookmark(created))
    }

    func test_addReadingBookmark_replacesExistingBookmark() async throws {
        let original = ayah(254)
        let destination = ayah(255)
        try await service.addReadingBookmark(at: .ayah(original), slot: .orange)

        try await service.addReadingBookmark(at: .ayah(destination), slot: .orange)
        let stored = try await storedBookmark(in: .orange)

        XCTAssertEqual(stored?.placement, .ayah(destination))
    }

    func test_clearReadingBookmark_clearsLocationButPreservesPin() async throws {
        let placed = try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .red)

        let cleared = try await service.clearReadingBookmark(in: .red)
        let stored = try await storedBookmark(in: .red)

        XCTAssertEqual(stored, cleared)
        XCTAssertEqual(stored?.id, placed.id)
        XCTAssertEqual(stored?.slot, .red)
        XCTAssertEqual(stored?.placement, .unplaced)
    }

    func test_readingBookmarksSequence_mapsMadani1405PageIntoEachReadersQuran() async throws {
        try await service.addReadingBookmark(at: .page(page(585, of: .hafsMadani1405)), slot: .teal)

        let madani1440 = try await storedBookmark(quran: .hafsMadani1440)
        let indoPak = try await storedBookmark(quran: .hafsIndoPak)

        XCTAssertEqual(madani1440?.placement, .page(page(585, of: .hafsMadani1440)))
        XCTAssertEqual(indoPak?.placement, .page(page(591, of: .hafsIndoPak)))
    }

    func test_readingBookmarksSequence_mapsIndoPakPageIntoMadaniAndBack() async throws {
        let indoPakPage = page(537, of: .hafsIndoPak)

        let madaniPage = page(536, of: .hafsMadani1440)

        let created = try await service.addReadingBookmark(at: .page(indoPakPage), slot: .teal)
        try await service.addReadingBookmark(at: .page(madaniPage), slot: .orange)
        let madani1440 = try await storedBookmarks(quran: .hafsMadani1440)
        let indoPak = try await storedBookmarks(quran: .hafsIndoPak)

        XCTAssertEqual(created.placement, .page(indoPakPage))
        XCTAssertEqual(madani1440.map(\.placement), [.page(madaniPage), .page(madaniPage)])
        XCTAssertEqual(indoPak.map(\.placement), [.page(indoPakPage), .page(indoPakPage)])
    }

    func test_readingBookmark_pageTheReadersQuranDoesNotHaveIsUnplaced() {
        let bookmark = MobileSyncReadingBookmarkService.readingBookmark(
            from: pageBookmark(page: 1, mushaf: .indopak15Lines, name: "Study"),
            quran: .hafsIndoPak
        )

        XCTAssertEqual(bookmark?.placement, .unplaced)
        XCTAssertEqual(bookmark?.slot, .teal)
        XCTAssertEqual(bookmark?.name, "Study")
    }

    func test_readingBookmark_pageReadInAnotherMushafIsUnplaced() {
        let bookmark = MobileSyncReadingBookmarkService.readingBookmark(
            from: pageBookmark(page: 255, mushaf: .madani1440),
            quran: .hafsMadani1405
        )

        XCTAssertEqual(bookmark?.placement, .unplaced)
    }

    func test_addReadingBookmark_persistsPageLocation() async throws {
        let storedPage = Quran.hafsMadani1405.pages[254]

        let created = try await service.addReadingBookmark(at: .page(storedPage), slot: .teal)
        let stored = try await storedBookmark()

        XCTAssertEqual(created.placement, .page(storedPage))
        XCTAssertEqual(stored?.placement, .page(storedPage))
    }

    func test_addReadingBookmarks_preservesEachSlot() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(254)), slot: .teal)
        try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .orange)

        let bookmarks = try await storedBookmarks()

        XCTAssertEqual(Set(bookmarks.map(\.slot)), [.teal, .orange])
    }

    func test_readingBookmarksSequence_ordersBookmarksBySlot() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(256)), slot: .red)
        try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .orange)
        try await service.addReadingBookmark(at: .ayah(ayah(254)), slot: .teal)

        let bookmarks = try await storedBookmarks()

        XCTAssertEqual(bookmarks.map(\.slot), [.teal, .orange, .red])
    }

    func test_addReadingBookmark_storesTheMatchingMobileSyncSlot() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(1)), slot: .teal)
        try await service.addReadingBookmark(at: .ayah(ayah(2)), slot: .orange)
        try await service.addReadingBookmark(at: .ayah(ayah(3)), slot: .red)

        let iterator = database.quranDataService.readingBookmarksSequence(mushaf: .madani1405).makeAsyncIterator()
        let bookmarks = try await iterator.next() ?? []

        // Other platforms read these slots, so a swapped mapping must fail even though it round-trips.
        let slots = bookmarks.compactMap { bookmark -> String? in
            guard case let .ayah(_, ayah) = bookmark.placement else { return nil }
            return "\(bookmark.slot) 2:\(ayah)"
        }
        XCTAssertEqual(slots.sorted(), ["orange 2:2", "red 2:3", "teal 2:1"])
    }

    func test_placedReadingBookmarksSequence_filtersUnplacedPinsAndPreservesMetadata() async throws {
        let red = try await service.addReadingBookmark(at: .ayah(ayah(256)), slot: .red)
        let teal = try await service.addReadingBookmark(at: .ayah(ayah(254)), slot: .teal)
        try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .orange)
        try await service.clearReadingBookmark(in: .orange)

        var iterator = service.placedReadingBookmarksSequence(quran: .hafsMadani1405).makeAsyncIterator()
        let placed = try await iterator.next()
        let all = try await storedBookmarks()

        XCTAssertEqual(all.map(\.slot), [.teal, .orange, .red])
        XCTAssertEqual(all.first { $0.slot == .orange }?.placement, .unplaced)
        XCTAssertEqual(placed, [
            PlacedReadingBookmark(
                id: teal.id, slot: .teal, placement: .ayah(ayah(254)),
                modifiedOn: teal.modifiedOn, name: teal.name
            ),
            PlacedReadingBookmark(
                id: red.id, slot: .red, placement: .ayah(ayah(256)),
                modifiedOn: red.modifiedOn, name: red.name
            ),
        ])
    }

    func test_placedReadingBookmarksSequence_mapsPageIntoRequestedQuran() async throws {
        try await service.addReadingBookmark(at: .page(page(585, of: .hafsMadani1405)), slot: .teal)
        let expectedPage = page(591, of: .hafsIndoPak)

        var iterator = service.placedReadingBookmarksSequence(quran: .hafsIndoPak).makeAsyncIterator()
        let placed = try await iterator.next()

        XCTAssertEqual(placed?.first?.placement, .page(expectedPage))
        XCTAssertEqual(placed?.first?.suras, expectedPage.suras)
    }

    func test_renameReadingBookmark_preservesPlacedBookmark() async throws {
        let original = try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .teal)

        let renamed = try await service.renameReadingBookmark(in: .teal, name: "Daily reading", quran: .hafsMadani1405)
        let stored = try await storedBookmark()

        XCTAssertEqual(stored, renamed)
        XCTAssertEqual(stored?.id, original.id)
        XCTAssertEqual(stored?.placement, .ayah(ayah(255)))
        XCTAssertEqual(stored?.name, "Daily reading")
    }

    func test_renameReadingBookmark_createsUnplacedPin() async throws {
        let renamed = try await service.renameReadingBookmark(in: .orange, name: "Review", quran: .hafsMadani1405)

        let stored = try await storedBookmark(in: .orange)
        XCTAssertEqual(stored, renamed)
        XCTAssertEqual(stored?.slot, .orange)
        XCTAssertEqual(stored?.placement, .unplaced)
        XCTAssertEqual(stored?.name, "Review")
    }

    func test_renameReadingBookmark_nilClearsNameWithoutClearingPage() async throws {
        let page = Quran.hafsMadani1405.pages[40]
        try await service.addReadingBookmark(at: .page(page), slot: .teal)
        try await service.renameReadingBookmark(in: .teal, name: "Review", quran: .hafsMadani1405)

        let renamed = try await service.renameReadingBookmark(in: .teal, name: nil, quran: .hafsMadani1405)
        let stored = try await storedBookmark()

        XCTAssertEqual(stored, renamed)
        XCTAssertNil(stored?.name)
        XCTAssertEqual(stored?.placement, .page(page))
    }

    func test_namedBookmark_preservesNameWhenMovedAndCleared() async throws {
        try await service.renameReadingBookmark(in: .teal, name: "Daily reading", quran: .hafsMadani1405)

        let moved = try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .teal)
        let cleared = try await service.clearReadingBookmark(in: .teal)

        XCTAssertEqual(moved.name, "Daily reading")
        XCTAssertEqual(cleared.name, "Daily reading")
        XCTAssertEqual(cleared.placement, .unplaced)
    }

    func test_renameReadingBookmark_returnsPageInRequestedQuran() async throws {
        try await service.addReadingBookmark(at: .page(page(537, of: .hafsIndoPak)), slot: .teal)

        let renamed = try await service.renameReadingBookmark(in: .teal, name: "Review", quran: .hafsMadani1440)
        let stored = try await storedBookmark(quran: .hafsMadani1440)

        XCTAssertEqual(renamed, stored)
        XCTAssertEqual(renamed.placement, .page(page(536, of: .hafsMadani1440)))
        XCTAssertEqual(renamed.name, "Review")
    }

    private func storedBookmark(
        in slot: ReadingBookmarkSlot = .teal,
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

    private func page(_ number: Int, of quran: Quran) -> Page {
        Page(quran: quran, pageNumber: number)!
    }

    private func pageBookmark(page: Int, mushaf: MobileSyncMushaf, name: String? = nil) -> MobileSyncReadingBookmark {
        MobileSyncReadingBookmark(
            id: "1",
            slot: .teal,
            placement: .page(page, mushaf: mushaf),
            name: name,
            lastUpdated: Date(timeIntervalSince1970: 0)
        )
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: number)!
    }
}
#endif

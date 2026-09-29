#if QURAN_SYNC
import class MobileSync.AyahReadingBookmark
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

        let created: PlacedReadingBookmark = try await service.addReadingBookmark(at: placement, slot: .green)
        let stored = try await storedBookmark()

        XCTAssertEqual(created.placement, .ayah(ayah))
        XCTAssertEqual(created.slot, .green)
        XCTAssertEqual(stored?.placement, .ayah(ayah))
        XCTAssertEqual(stored, ReadingBookmark(created))
    }

    func test_addReadingBookmark_replacesExistingBookmark() async throws {
        let original = ayah(254)
        let destination = ayah(255)
        try await service.addReadingBookmark(at: .ayah(original), slot: .purple)

        try await service.addReadingBookmark(at: .ayah(destination), slot: .purple)
        let stored = try await storedBookmark(in: .purple)

        XCTAssertEqual(stored?.placement, .ayah(destination))
    }

    func test_clearReadingBookmark_clearsLocationButPreservesPin() async throws {
        let placed = try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .blue)

        let cleared = try await service.clearReadingBookmark(in: .blue)
        let stored = try await storedBookmark(in: .blue)

        XCTAssertEqual(stored, cleared)
        XCTAssertEqual(stored?.id, placed.id)
        XCTAssertEqual(stored?.slot, .blue)
        XCTAssertEqual(stored?.placement, .unplaced)
    }

    func test_readingBookmarkSequence_mapsPageIntoRequestedQuran() async throws {
        let storedPage = Quran.hafsMadani1405.pages[254]
        _ = try await service.addReadingBookmark(at: .page(storedPage), slot: .green)
        let quran = Quran.hafsIndoPak
        let expectedPage = try XCTUnwrap(QuranPageMapper(destination: quran).mapPage(storedPage))

        let bookmark = try await storedBookmark(quran: quran)

        XCTAssertEqual(bookmark?.placement, .page(expectedPage))
    }

    func test_addReadingBookmark_persistsPageLocation() async throws {
        let storedPage = Quran.hafsMadani1405.pages[254]

        let created = try await service.addReadingBookmark(at: .page(storedPage), slot: .green)
        let stored = try await storedBookmark()

        XCTAssertEqual(created.placement, .page(storedPage))
        XCTAssertEqual(stored?.placement, .page(storedPage))
    }

    func test_addReadingBookmarks_preservesEachSlot() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(254)), slot: .green)
        try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .purple)

        let bookmarks = try await storedBookmarks()

        XCTAssertEqual(Set(bookmarks.map(\.slot)), [.green, .purple])
    }

    func test_readingBookmarksSequence_ordersBookmarksBySlot() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(256)), slot: .blue)
        try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .purple)
        try await service.addReadingBookmark(at: .ayah(ayah(254)), slot: .green)

        let bookmarks = try await storedBookmarks()

        XCTAssertEqual(bookmarks.map(\.slot), [.green, .purple, .blue])
    }

    func test_addReadingBookmark_storesTheMatchingMobileSyncSlot() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(1)), slot: .green)
        try await service.addReadingBookmark(at: .ayah(ayah(2)), slot: .purple)
        try await service.addReadingBookmark(at: .ayah(ayah(3)), slot: .blue)

        let iterator = database.quranDataService.readingBookmarksSequence().makeAsyncIterator()
        let bookmarks = try await iterator.next() ?? []

        // Other platforms read these slots, so a swapped mapping must fail even though it round-trips.
        let slots = bookmarks.compactMap { bookmark -> String? in
            guard let bookmark = bookmark as? AyahReadingBookmark else { return nil }
            return "\(bookmark.slot.name) 2:\(bookmark.ayah)"
        }
        XCTAssertEqual(slots.sorted(), ["ORANGE 2:2", "RED 2:3", "TEAL 2:1"])
    }

    func test_placedReadingBookmarksSequence_filtersUnplacedPinsAndPreservesMetadata() async throws {
        let blue = try await service.addReadingBookmark(at: .ayah(ayah(256)), slot: .blue)
        let green = try await service.addReadingBookmark(at: .ayah(ayah(254)), slot: .green)
        try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .purple)
        try await service.clearReadingBookmark(in: .purple)

        var iterator = service.placedReadingBookmarksSequence(quran: .hafsMadani1405).makeAsyncIterator()
        let placed = try await iterator.next()
        let all = try await storedBookmarks()

        XCTAssertEqual(all.map(\.slot), [.green, .purple, .blue])
        XCTAssertEqual(all.first { $0.slot == .purple }?.placement, .unplaced)
        XCTAssertEqual(placed, [
            PlacedReadingBookmark(
                id: green.id, slot: .green, placement: .ayah(ayah(254)),
                modifiedOn: green.modifiedOn, name: green.name
            ),
            PlacedReadingBookmark(
                id: blue.id, slot: .blue, placement: .ayah(ayah(256)),
                modifiedOn: blue.modifiedOn, name: blue.name
            ),
        ])
    }

    func test_placedReadingBookmarksSequence_mapsPageIntoRequestedQuran() async throws {
        let storedPage = Quran.hafsMadani1405.pages[254]
        try await service.addReadingBookmark(at: .page(storedPage), slot: .green)
        let quran = Quran.hafsIndoPak
        let expectedPage = try XCTUnwrap(QuranPageMapper(destination: quran).mapPage(storedPage))

        var iterator = service.placedReadingBookmarksSequence(quran: quran).makeAsyncIterator()
        let placed = try await iterator.next()

        XCTAssertEqual(placed?.first?.placement, .page(expectedPage))
        XCTAssertEqual(placed?.first?.sura, expectedPage.firstVerse.sura)
    }

    func test_renameReadingBookmark_preservesPlacedBookmark() async throws {
        let original = try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .green)

        let renamed = try await service.renameReadingBookmark(in: .green, name: "Daily reading", quran: .hafsMadani1405)
        let stored = try await storedBookmark()

        XCTAssertEqual(stored, renamed)
        XCTAssertEqual(stored?.id, original.id)
        XCTAssertEqual(stored?.placement, .ayah(ayah(255)))
        XCTAssertEqual(stored?.name, "Daily reading")
    }

    func test_renameReadingBookmark_createsUnplacedPin() async throws {
        let renamed = try await service.renameReadingBookmark(in: .purple, name: "Review", quran: .hafsMadani1405)

        let stored = try await storedBookmark(in: .purple)
        XCTAssertEqual(stored, renamed)
        XCTAssertEqual(stored?.slot, .purple)
        XCTAssertEqual(stored?.placement, .unplaced)
        XCTAssertEqual(stored?.name, "Review")
    }

    func test_renameReadingBookmark_nilClearsNameWithoutClearingPage() async throws {
        let page = Quran.hafsMadani1405.pages[40]
        try await service.addReadingBookmark(at: .page(page), slot: .green)
        try await service.renameReadingBookmark(in: .green, name: "Review", quran: .hafsMadani1405)

        let renamed = try await service.renameReadingBookmark(in: .green, name: nil, quran: .hafsMadani1405)
        let stored = try await storedBookmark()

        XCTAssertEqual(stored, renamed)
        XCTAssertNil(stored?.name)
        XCTAssertEqual(stored?.placement, .page(page))
    }

    func test_namedBookmark_preservesNameWhenMovedAndCleared() async throws {
        try await service.renameReadingBookmark(in: .green, name: "Daily reading", quran: .hafsMadani1405)

        let moved = try await service.addReadingBookmark(at: .ayah(ayah(255)), slot: .green)
        let cleared = try await service.clearReadingBookmark(in: .green)

        XCTAssertEqual(moved.name, "Daily reading")
        XCTAssertEqual(cleared.name, "Daily reading")
        XCTAssertEqual(cleared.placement, .unplaced)
    }

    func test_renameReadingBookmark_returnsPageInRequestedQuran() async throws {
        let page = Quran.hafsMadani1405.pages[40]
        try await service.addReadingBookmark(at: .page(page), slot: .green)
        let quran = Quran.hafsIndoPak
        let mappedPage = try XCTUnwrap(QuranPageMapper(destination: quran).mapPage(page))

        let renamed = try await service.renameReadingBookmark(in: .green, name: "Review", quran: quran)
        let stored = try await storedBookmark(quran: quran)

        XCTAssertEqual(renamed, stored)
        XCTAssertEqual(renamed.placement, .page(mappedPage))
        XCTAssertEqual(renamed.name, "Review")
    }

    private func storedBookmark(
        in slot: ReadingBookmarkSlot = .green,
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

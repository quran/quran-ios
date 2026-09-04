#if QURAN_SYNC
import Foundation
import QuranAnnotations
import QuranKit
import XCTest
@testable import QuranViewFeature

final class ReadingBookmarkSelectionTests: XCTestCase {
    func test_latest_returnsMostRecentlyModifiedBookmarkAtLocation() {
        let page = Quran.hafsMadani1405.pages[2]
        let older = bookmark(slot: .coral, placement: .page(page), modifiedOn: Date(timeIntervalSince1970: 1))
        let newer = bookmark(slot: .teal, placement: .page(page), modifiedOn: Date(timeIntervalSince1970: 2))
        let unrelated = bookmark(
            slot: .indigo,
            placement: .page(Quran.hafsMadani1405.pages[3]),
            modifiedOn: Date(timeIntervalSince1970: 3)
        )

        let selected = ReadingBookmarkSelection.latest(
            at: .page(page),
            in: [newer, unrelated, older]
        )

        XCTAssertEqual(selected, newer)
    }

    func test_latest_returnsNilWithoutBookmarkAtLocation() {
        let page = Quran.hafsMadani1405.pages[2]

        let selected = ReadingBookmarkSelection.latest(at: .page(page), in: [])

        XCTAssertNil(selected)
    }

    func test_latest_returnsMostRecentlyModifiedBookmarkAcrossLocations() {
        let firstPage = Quran.hafsMadani1405.pages[2]
        let secondPage = Quran.hafsMadani1405.pages[3]
        let older = bookmark(slot: .coral, placement: .page(firstPage), modifiedOn: Date(timeIntervalSince1970: 1))
        let newer = bookmark(slot: .teal, placement: .page(secondPage), modifiedOn: Date(timeIntervalSince1970: 2))
        let unrelated = bookmark(
            slot: .indigo,
            placement: .page(Quran.hafsMadani1405.pages[4]),
            modifiedOn: Date(timeIntervalSince1970: 3)
        )

        let selected = ReadingBookmarkSelection.latest(
            at: [.page(firstPage), .page(secondPage)],
            in: [older, unrelated, newer]
        )

        XCTAssertEqual(selected, newer)
    }

    func test_latest_returnsNilWithoutRequestedPlacements() {
        let page = Quran.hafsMadani1405.pages[2]
        let placed = bookmark(slot: .teal, placement: .page(page), modifiedOn: .distantPast)

        XCTAssertNil(ReadingBookmarkSelection.latest(at: [], in: [placed]))
    }

    private func bookmark(
        slot: ReadingBookmarkSlot,
        placement: PlacedReadingBookmark.Placement,
        modifiedOn: Date
    ) -> PlacedReadingBookmark {
        PlacedReadingBookmark(
            id: String(describing: slot),
            slot: slot,
            placement: placement,
            modifiedOn: modifiedOn
        )
    }
}
#endif

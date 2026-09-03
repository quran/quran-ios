#if QURAN_SYNC
import Foundation
import QuranAnnotations
import QuranKit
import XCTest
@testable import QuranViewFeature

final class ReadingBookmarkSelectionTests: XCTestCase {
    func test_latest_returnsMostRecentlyModifiedBookmarkAtLocation() {
        let page = Quran.hafsMadani1405.pages[2]
        let older = bookmark(slot: .coral, location: .page(page), modifiedOn: Date(timeIntervalSince1970: 1))
        let newer = bookmark(slot: .teal, location: .page(page), modifiedOn: Date(timeIntervalSince1970: 2))
        let unrelated = bookmark(
            slot: .indigo,
            location: .page(Quran.hafsMadani1405.pages[3]),
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
        let older = bookmark(slot: .coral, location: .page(firstPage), modifiedOn: Date(timeIntervalSince1970: 1))
        let newer = bookmark(slot: .teal, location: .page(secondPage), modifiedOn: Date(timeIntervalSince1970: 2))
        let unrelated = bookmark(
            slot: .indigo,
            location: .page(Quran.hafsMadani1405.pages[4]),
            modifiedOn: Date(timeIntervalSince1970: 3)
        )

        let selected = ReadingBookmarkSelection.latest(
            at: [.page(firstPage), .page(secondPage)],
            in: [older, unrelated, newer]
        )

        XCTAssertEqual(selected, newer)
    }

    private func bookmark(
        slot: ReadingBookmarkSlot,
        location: ReadingPositionBookmark.Location,
        modifiedOn: Date
    ) -> ReadingPositionBookmark {
        ReadingPositionBookmark(
            id: String(describing: slot),
            slot: slot,
            location: location,
            modifiedOn: modifiedOn
        )
    }
}
#endif

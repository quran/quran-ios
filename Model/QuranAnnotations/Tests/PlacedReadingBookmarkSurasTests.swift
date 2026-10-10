#if QURAN_SYNC
import Foundation
import QuranAnnotations
import QuranKit
import XCTest

final class PlacedReadingBookmarkSurasTests: XCTestCase {
    func test_suras_pageBookmarkListsSuraStartingMidPage() {
        let page = Quran.hafsMadani1405.pages[292]

        XCTAssertEqual(bookmark(at: .page(page)).suras.map(\.suraNumber), [17, 18])
    }

    func test_suras_ayahBookmarkListsOnlyItsSura() {
        let ayah = Quran.hafsMadani1405.suras[17].verses[0]

        XCTAssertEqual(bookmark(at: .ayah(ayah)).suras.map(\.suraNumber), [18])
    }

    private func bookmark(at placement: PlacedReadingBookmark.Placement) -> PlacedReadingBookmark {
        PlacedReadingBookmark(id: "bookmark", slot: .orange, placement: placement, modifiedOn: Date(timeIntervalSince1970: 0))
    }
}
#endif

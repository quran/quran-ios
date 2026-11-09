#if QURAN_SYNC
import Foundation
import QuranAnnotations
import QuranKit
import XCTest

final class PlacedReadingBookmarkPageTests: XCTestCase {
    func test_page_pageBookmarkUsesItsPage() {
        let page = Quran.hafsMadani1405.pages[22]

        XCTAssertEqual(bookmark(at: .page(page)).page, page)
    }

    func test_page_ayahBookmarkUsesThePageHoldingTheAyah() {
        let ayah = Quran.hafsMadani1405.suras[66].verses[17]

        XCTAssertEqual(bookmark(at: .ayah(ayah)).page.pageNumber, 563)
    }

    func test_page_ayahThatOpensAPageUsesThatPage() {
        let ayah = Quran.hafsMadani1405.suras[66].verses[12]

        XCTAssertEqual(bookmark(at: .ayah(ayah)).page.pageNumber, 563)
    }

    func test_page_lastAyahOnAPageUsesThatPage() {
        let ayah = Quran.hafsMadani1405.suras[66].verses[11]

        XCTAssertEqual(bookmark(at: .ayah(ayah)).page.pageNumber, 562)
    }

    private func bookmark(at placement: PlacedReadingBookmark.Placement) -> PlacedReadingBookmark {
        PlacedReadingBookmark(id: "bookmark", slot: .orange, placement: placement, modifiedOn: Date(timeIntervalSince1970: 0))
    }
}
#endif

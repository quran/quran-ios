#if QURAN_SYNC
import Foundation
import QuranAnnotations
import QuranKit
import XCTest
@testable import QuranViewFeature

final class ReadingBookmarkActionTests: XCTestCase {
    private let quran = Quran.hafsMadani1405

    func test_emptyVisiblePages_hasNoAction() {
        XCTAssertNil(ReadingBookmarkAction.page(visiblePages: [], bookmark: nil))
    }

    func test_noBookmark_setsBookmarkOnLowerVisiblePage() {
        let lowerPage = quran.pages[40]
        let upperPage = quran.pages[41]

        let action = ReadingBookmarkAction.page(
            visiblePages: [upperPage, lowerPage],
            bookmark: nil
        )

        XCTAssertEqual(action, .set(location: .page(lowerPage), replacing: nil))
    }

    func test_exactPageBookmark_removesBookmark() {
        let page = quran.pages[40]
        let bookmark = bookmark(at: .page(page))

        let action = ReadingBookmarkAction.page(visiblePages: [page], bookmark: bookmark)

        XCTAssertEqual(action, .remove(bookmark))
    }

    func test_differentPageBookmark_replacesBookmark() {
        let currentPage = quran.pages[40]
        let targetPage = quran.pages[41]
        let bookmark = bookmark(at: .page(currentPage))

        let action = ReadingBookmarkAction.page(visiblePages: [targetPage], bookmark: bookmark)

        XCTAssertEqual(action, .set(location: .page(targetPage), replacing: bookmark))
    }

    func test_ayahBookmarkOnTargetPage_replacesBookmarkWithPage() {
        let page = quran.pages[40]
        let bookmark = bookmark(at: .ayah(page.firstVerse))

        let action = ReadingBookmarkAction.page(visiblePages: [page], bookmark: bookmark)

        XCTAssertEqual(action, .set(location: .page(page), replacing: bookmark))
    }

    private func bookmark(at location: ReadingPositionBookmark.Location) -> ReadingPositionBookmark {
        ReadingPositionBookmark(id: "reading-bookmark", location: location, modifiedOn: .distantPast)
    }
}
#endif

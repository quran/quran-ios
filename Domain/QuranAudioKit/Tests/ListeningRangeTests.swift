import QuranKit
import XCTest
@testable import QuranAudioKit

final class ListeningRangeTests: XCTestCase {
    func test_onePageKeepsTheUnfinishedVerseAndEndsAtItsPageBoundary() throws {
        let page = try XCTUnwrap(Page(quran: .hafsMadani1405, pageNumber: 20))
        let start = try XCTUnwrap(page.firstVerse.next)
        let range = try ListeningRange(from: start, pageCount: 1)

        XCTAssertEqual(range.start, start)
        XCTAssertEqual(range.end, page.lastVerse)
    }

    func test_fivePagesIncludesTheStartingPage() throws {
        let quran = Quran.hafsMadani1405
        let start = try XCTUnwrap(Page(quran: quran, pageNumber: 20)).firstVerse
        let range = try ListeningRange(from: start, pageCount: 5)

        XCTAssertEqual(range.end, Page(quran: quran, pageNumber: 24)?.lastVerse)
    }

    func test_pagesCanCrossSurahs() throws {
        let quran = Quran.hafsMadani1405
        let range = try ListeningRange(from: quran.firstVerse, pageCount: 5)

        XCTAssertEqual(range.start.sura.suraNumber, 1)
        XCTAssertEqual(range.end.sura.suraNumber, 2)
        XCTAssertEqual(range.end, Page(quran: quran, pageNumber: 5)?.lastVerse)
    }

    func test_usesIndoPakPageNumbering() throws {
        let quran = Quran.hafsIndoPak
        let range = try ListeningRange(from: quran.firstVerse, pageCount: 5)

        XCTAssertEqual(range.start.page.pageNumber, 2)
        XCTAssertEqual(range.end, Page(quran: quran, pageNumber: 6)?.lastVerse)
    }

    func test_largeCountsClampWithoutOverflow() throws {
        for quran in [Quran.hafsMadani1405, .hafsMadani1440, .hafsIndoPak] {
            let range = try ListeningRange(from: quran.lastVerse, pageCount: Int.max)
            XCTAssertEqual(range.start, quran.lastVerse)
            XCTAssertEqual(range.end, quran.lastVerse)
        }
    }

    func test_rejectsNonPositiveCounts() {
        for count in [Int.min, -1, 0] {
            XCTAssertThrowsError(try ListeningRange(from: Quran.hafsMadani1405.firstVerse, pageCount: count)) {
                XCTAssertEqual($0 as? ListeningRange.Error, .invalidPageCount)
            }
        }
    }
}

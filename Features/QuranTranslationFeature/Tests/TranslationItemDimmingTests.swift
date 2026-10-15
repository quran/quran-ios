import QuranKit
import XCTest
@testable import QuranTranslationFeature

final class TranslationItemDimmingTests: XCTestCase {
    func testNothingIsDimmedWithoutFocus() {
        for id in rowIds(for: recited) + chromeIds {
            XCTAssertFalse(id.isDimmed(by: nil), "\(id)")
        }
    }

    func testPageHeaderAndFooterAreNeverDimmed() {
        for id in chromeIds {
            XCTAssertFalse(id.isDimmed(by: [recited]), "\(id)")
            XCTAssertFalse(id.isDimmed(by: []), "\(id)")
        }
    }

    func testSuraNameFollowsTheSurasFirstVerse() {
        let sura = Quran.hafsMadani1405.suras[1]

        XCTAssertFalse(TranslationItemId.suraName(sura).isDimmed(by: [sura.firstVerse]))
        XCTAssertTrue(TranslationItemId.suraName(sura).isDimmed(by: [sura.verses[1]]))
    }

    func testVerseRowsAreDimmedUnlessTheirVerseIsFocused() {
        for id in rowIds(for: recited) {
            XCTAssertFalse(id.isDimmed(by: [recited]), "\(id)")
        }
        for id in rowIds(for: other) {
            XCTAssertTrue(id.isDimmed(by: [recited]), "\(id)")
        }
    }

    func testSeparatorFollowsItsVerse() {
        XCTAssertFalse(TranslationItemId.separator(recited).isDimmed(by: [recited]))
        XCTAssertTrue(TranslationItemId.separator(other).isDimmed(by: [recited]))
    }

    func testEmptyFocusDimsEveryVerseRow() {
        let sura = Quran.hafsMadani1405.suras[1]

        for id in rowIds(for: recited) + rowIds(for: other) + [.suraName(sura)] {
            XCTAssertTrue(id.isDimmed(by: []), "\(id)")
        }
    }

    private var recited: AyahNumber {
        Quran.hafsMadani1405.suras[1].verses[1]
    }

    private var other: AyahNumber {
        Quran.hafsMadani1405.suras[1].verses[2]
    }

    private var chromeIds: [TranslationItemId] {
        let page = recited.page
        return [.pageHeader(page), .pageFooter(page)]
    }

    private func rowIds(for verse: AyahNumber) -> [TranslationItemId] {
        [
            .separator(verse),
            .arabic(verse),
            .verseNumber(verse),
            .translator(verse, translationId: 1),
            .translationReference(verse, translationId: 1),
            .translationTextChunk(verse, translationId: 1, chunkIndex: 0),
        ]
    }
}

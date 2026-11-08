import QuranKit
import XCTest
@testable import QuranTranslationFeature

final class TranslationItemDimmingTests: XCTestCase {
    func testNothingIsDimmedWhileDimOtherAyahsIsOff() {
        for id in rowIds(for: recited) + chromeIds {
            XCTAssertFalse(id.isDimmed(undimmedVerses: nil), "\(id)")
        }
    }

    func testPageHeaderAndFooterAreNeverDimmed() {
        for id in chromeIds {
            XCTAssertFalse(id.isDimmed(undimmedVerses: []), "\(id)")
        }
    }

    func testSuraNameIsUndimmedWithTheSurasFirstVerse() {
        let sura = Quran.hafsMadani1405.suras[1]

        XCTAssertFalse(TranslationItemId.suraName(sura).isDimmed(undimmedVerses: [sura.firstVerse]))
    }

    func testSuraNameIsDimmedWithTheSurasOtherVerses() {
        let sura = Quran.hafsMadani1405.suras[1]

        XCTAssertTrue(TranslationItemId.suraName(sura).isDimmed(undimmedVerses: [sura.verses[1]]))
    }

    func testRowsOfAnUndimmedVerseAreNotDimmed() {
        for id in rowIds(for: recited) {
            XCTAssertFalse(id.isDimmed(undimmedVerses: [recited]), "\(id)")
        }
    }

    func testRowsOfOtherVersesAreDimmed() {
        for id in rowIds(for: other) {
            XCTAssertTrue(id.isDimmed(undimmedVerses: [recited]), "\(id)")
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

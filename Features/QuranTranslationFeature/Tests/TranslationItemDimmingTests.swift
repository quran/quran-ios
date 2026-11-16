import AnnotationsService
import QuranKit
import QuranText
import QuranTextKit
import XCTest
@testable import QuranTranslationFeature

@MainActor
final class TranslationItemDimmingTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        QuranContentStatePreferences.shared.showArabicInTranslation = true
    }

    override func tearDown() {
        QuranContentStatePreferences.shared.showArabicInTranslation = true
        super.tearDown()
    }

    func testNothingIsDimmedWhileDimOtherAyahsIsOff() {
        let sut = makeSUT()

        service.overlays.playingVerses = [recited]

        for id in rowIds(for: other) + chromeIds + [.suraName(sura)] {
            XCTAssertEqual(isDimmed(id, in: sut), false, "\(id)")
        }
    }

    func testPageHeaderAndFooterAreNeverDimmed() {
        let sut = makeSUT()

        play(Quran.hafsMadani1405.firstVerse)

        let items = sut.items(quranFont: .uthmanicHafs)
        XCTAssertEqual(items.first?.id, .pageHeader(recited.page))
        XCTAssertEqual(items.last?.id, .pageFooter(recited.page))
        XCTAssertEqual(dimmedIds(in: sut), Set(items.map(\.id)).subtracting(chromeIds))
    }

    func testSuraNameIsUndimmedWithTheSurasFirstVerse() {
        let sut = makeSUT()

        play(sura.firstVerse)

        XCTAssertEqual(isDimmed(.suraName(sura), in: sut), false)
    }

    func testSuraNameIsDimmedWithTheSurasOtherVerses() {
        let sut = makeSUT()

        play(recited)

        XCTAssertEqual(isDimmed(.suraName(sura), in: sut), true)
    }

    func testRowsOfAnUndimmedVerseAreNotDimmed() {
        let sut = makeSUT()

        play(recited)

        for id in rowIds(for: recited) {
            XCTAssertEqual(isDimmed(id, in: sut), false, "\(id)")
        }
    }

    func testRowsOfOtherVersesAreDimmed() {
        let sut = makeSUT()

        play(recited)

        for id in rowIds(for: other) {
            XCTAssertEqual(isDimmed(id, in: sut), true, "\(id)")
        }
    }

    // MARK: Private

    private let service = VerseOverlayService()

    private var sura: Sura {
        Quran.hafsMadani1405.suras[1]
    }

    private var verses: [AyahNumber] {
        Array(sura.verses.prefix(4))
    }

    private var recited: AyahNumber {
        verses[1]
    }

    private var other: AyahNumber {
        verses[2]
    }

    private var chromeIds: Set<TranslationItemId> {
        [.pageHeader(recited.page), .pageFooter(recited.page)]
    }

    /// Every row kind a verse shows with a text and a reference translation.
    private func rowIds(for verse: AyahNumber) -> [TranslationItemId] {
        [
            .separator(verse),
            .arabic(verse),
            .verseNumber(verse),
            .translator(verse, translationId: 1),
            .translator(verse, translationId: 2),
            .translationReference(verse, translationId: 2),
            .translationTextChunk(verse, translationId: 1, chunkIndex: 0),
        ]
    }

    private func play(_ verse: AyahNumber) {
        service.overlays.dimsOtherAyahs = true
        service.overlays.playingVerses = [verse]
    }

    /// `nil` when the view model built no such item.
    private func isDimmed(_ id: TranslationItemId, in viewModel: ContentTranslationViewModel) -> Bool? {
        viewModel.items(quranFont: .uthmanicHafs).first { $0.id == id }?.decoration.isDimmed
    }

    private func dimmedIds(in viewModel: ContentTranslationViewModel) -> Set<TranslationItemId> {
        Set(viewModel.items(quranFont: .uthmanicHafs).filter(\.decoration.isDimmed).map(\.id))
    }

    private func makeSUT() -> ContentTranslationViewModel {
        let sut = makeContentTranslationViewModel(overlayService: service)
        sut.verses = verses
        let text = makeVerseText(translationCount: 1)
        sut.commitLoadedContent(
            verses: verses,
            translations: [makeTranslation(id: 1), makeTranslation(id: 2)],
            verseTexts: Dictionary(uniqueKeysWithValues: verses.map { verse in
                (verse, VerseText(
                    arabicText: text.arabicText,
                    translations: text.translations + [.reference(sura.firstVerse)],
                    arabicPrefix: [],
                    arabicSuffix: []
                ))
            })
        )
        return sut
    }
}

//
//  ContentTranslationViewModelTests.swift
//

import AnnotationsService
import Combine
import QuranAnnotations
import QuranKit
import QuranText
import QuranTextKit
import ReadingService
import XCTest
@testable import QuranTranslationFeature

@MainActor
final class ContentTranslationViewModelTests: XCTestCase {
    #if QURAN_SYNC
    func testVerseNumberItemsIncludeLiveAnnotationsAndRemoveClearedBadges() throws {
        let verse = Quran.hafsMadani1405.firstVerse
        let service = VerseOverlayService()
        let sut = makeSUT(overlayService: service)
        sut.verses = [verse]
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(translationCount: 1)]
        )
        let originalItem = try verseNumberItem(in: sut)

        service.overlays.notedVerses = [verse]
        service.overlays.collectionVerses = [verse]
        service.overlays.readingBookmarks = [
            .init(id: "teal", slot: .teal, placement: .ayah(verse), modifiedOn: .distantPast),
            .init(id: "orange", slot: .orange, placement: .ayah(verse), modifiedOn: .distantPast),
            .init(id: "page", slot: .red, placement: .page(verse.page), modifiedOn: .distantPast),
        ]

        let annotatedItem = try verseNumberItem(in: sut)
        XCTAssertEqual(annotatedItem.annotations, [.note, .collection, .readingBookmark(.teal), .readingBookmark(.orange)])
        XCTAssertEqual(annotatedItem.id, originalItem.id)
        XCTAssertNotEqual(annotatedItem, originalItem)

        service.overlays.notedVerses = []
        service.overlays.collectionVerses = []
        service.overlays.readingBookmarks = []

        XCTAssertEqual(try verseNumberItem(in: sut), originalItem)
    }

    func testAnnotationsFollowChangesToDisplayedVerses() {
        let first = Quran.hafsMadani1405.pages[0].firstVerse
        let second = Quran.hafsMadani1405.pages[1].firstVerse
        let service = VerseOverlayService()
        service.overlays.notedVerses = [first]
        service.overlays.collectionVerses = [second]
        let sut = makeSUT(overlayService: service)

        sut.verses = [first]
        XCTAssertEqual(sut.annotationsByVerse, [first: [.note]])

        sut.verses = [second]
        XCTAssertEqual(sut.annotationsByVerse, [second: [.collection]])
    }

    func testUnrelatedOverlayChangesDoNotRepublishTranslationAnnotations() {
        let verse = Quran.hafsMadani1405.pages[0].firstVerse
        let other = Quran.hafsMadani1405.pages[1].firstVerse
        let service = VerseOverlayService()
        let sut = makeSUT(overlayService: service)
        sut.verses = [verse]
        var updates = 0
        let subscription = sut.$annotationsByVerse.dropFirst().sink { _ in updates += 1 }
        defer { subscription.cancel() }

        service.overlays.notedVerses = [other]
        service.overlays.collectionVerses = [other]
        service.overlays.colorHighlights = [verse: .green]

        XCTAssertEqual(updates, 0)

        service.overlays.notedVerses.insert(verse)
        service.overlays.notedVerses.insert(verse)

        XCTAssertEqual(updates, 1)
        XCTAssertEqual(sut.annotationsByVerse, [verse: [.note]])
    }

    func testHiddenArabicTextKeepsAnnotationsOnVerseNumber() throws {
        hideArabicText()
        let verse = Quran.hafsMadani1405.firstVerse
        let service = VerseOverlayService()
        service.overlays.notedVerses = [verse]
        let sut = makeSUT(overlayService: service)
        sut.verses = [verse]
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(translationCount: 1)]
        )

        let verseNumber = try XCTUnwrap(verseNumbers(in: sut).first)

        XCTAssertEqual(verseNumber.annotations, [.note])
    }

    private func verseNumberItem(in viewModel: ContentTranslationViewModel) throws -> TranslationVerseNumber {
        try XCTUnwrap(verseNumbers(in: viewModel).first)
    }
    #endif

    func testVerseNumberPrecedesArabicText() {
        let verse = Quran.hafsMadani1405.firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(translationCount: 1)]
        )

        let ids = sut.items(quranFont: .uthmanicHafs).map(\.id)

        XCTAssertEqual(ids.firstIndex(of: .verseNumber(verse)).map { $0 + 1 }, ids.firstIndex(of: .arabic(verse)))
    }

    func testHiddenArabicTextShowsVerseNumbersWithoutBesmAllah() throws {
        hideArabicText()
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(translationCount: 1)]
        )

        let items = sut.items(quranFont: .uthmanicHafs)

        XCTAssertFalse(items.contains { $0.id == .arabic(verse) })
        XCTAssertEqual(verseNumbers(in: sut).map(\.verse), [verse])
        XCTAssertEqual(try suraName(in: items).showsBesmAllah, false)
    }

    func testArabicTextStaysVisibleWithoutTranslations() throws {
        hideArabicText()
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [],
            verseTexts: [verse: makeVerseText(translationCount: 0)]
        )

        let items = sut.items(quranFont: .uthmanicHafs)

        XCTAssertTrue(items.contains { $0.id == .arabic(verse) })
        XCTAssertEqual(verseNumbers(in: sut).map(\.verse), [verse])
        XCTAssertEqual(try suraName(in: items).showsBesmAllah, true)
    }

    func testArabicTextVisibilityFollowsPreference() {
        let verse = Quran.hafsMadani1405.firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(translationCount: 1)]
        )
        XCTAssertTrue(sut.items(quranFont: .uthmanicHafs).contains { $0.id == .arabic(verse) })

        hideArabicText()

        XCTAssertFalse(sut.showArabicText)
        XCTAssertFalse(sut.items(quranFont: .uthmanicHafs).contains { $0.id == .arabic(verse) })
        XCTAssertTrue(sut.items(quranFont: .uthmanicHafs).contains { $0.id == .verseNumber(verse) })
    }

    func testPlaceholderTranslationsShowNoRows() {
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let translations = (1 ... 5).map(makeTranslation)
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: translations,
            verseTexts: [verse: makeVerseText(["Translation", "...", " … \n", "", " . . "])]
        )

        XCTAssertEqual(verseIds(in: sut), [
            .suraName(verse.sura),
            .verseNumber(verse),
            .arabic(verse),
            .translationTextChunk(verse, translationId: 1, chunkIndex: 0),
            .translator(verse, translationId: 1),
        ])
    }

    func testPlaceholderIsHiddenBesideTheArabicText() {
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(["..."])]
        )

        XCTAssertEqual(verseIds(in: sut), [.suraName(verse.sura), .verseNumber(verse), .arabic(verse)])
    }

    func testHiddenArabicTextHidesPlaceholderBesideAnotherTranslation() {
        hideArabicText()
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1), makeTranslation(id: 2)],
            verseTexts: [verse: makeVerseText(["...", "Translation"])]
        )

        XCTAssertEqual(verseIds(in: sut), [
            .suraName(verse.sura),
            .verseNumber(verse),
            .translationTextChunk(verse, translationId: 2, chunkIndex: 0),
            .translator(verse, translationId: 2),
        ])
    }

    func testHiddenArabicTextKeepsPlaceholdersWhenTheyAreTheVerseOnlyText() {
        hideArabicText()
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1), makeTranslation(id: 2)],
            verseTexts: [verse: makeVerseText(["...", "…"])]
        )

        XCTAssertEqual(verseIds(in: sut), [
            .suraName(verse.sura),
            .verseNumber(verse),
            .translationTextChunk(verse, translationId: 1, chunkIndex: 0),
            .translator(verse, translationId: 1),
            .translationTextChunk(verse, translationId: 2, chunkIndex: 0),
            .translator(verse, translationId: 2),
        ])
    }

    func testHighlightsFollowChangesToDisplayedVerses() {
        let first = Quran.hafsMadani1405.pages[0].firstVerse
        let second = Quran.hafsMadani1405.pages[1].firstVerse
        let service = VerseOverlayService()
        service.overlays.colorHighlights = [first: .green, second: .blue]
        let sut = makeSUT(overlayService: service)

        sut.verses = [first]
        XCTAssertEqual(Set(sut.highlights.keys), [first])

        sut.verses = [second]
        XCTAssertEqual(Set(sut.highlights.keys), [second])
    }

    func testUnrelatedOverlayChangesDoNotRepublishTranslationHighlights() {
        let verse = Quran.hafsMadani1405.pages[0].firstVerse
        let other = Quran.hafsMadani1405.pages[1].firstVerse
        let service = VerseOverlayService()
        let sut = makeSUT(overlayService: service)
        sut.verses = [verse]
        var updates = 0
        let subscription = sut.$highlights.dropFirst().sink { _ in updates += 1 }
        defer { subscription.cancel() }

        service.overlays.colorHighlights = [other: .green]
        service.overlays.notedVerses = [verse]
        service.overlays.annotationsHidden = true

        XCTAssertEqual(updates, 0)

        service.overlays.colorHighlights[verse] = .blue

        XCTAssertEqual(updates, 1)
        XCTAssertEqual(Set(sut.highlights.keys), [verse])
    }

    func testReadingUpdatesFromPreferences() {
        let preferences = ReadingPreferences.shared
        let originalReading = preferences.reading
        defer { preferences.reading = originalReading }
        preferences.reading = .hafs_1405
        let sut = makeSUT()

        preferences.reading = .indoPak

        XCTAssertEqual(sut.reading, .indoPak)
    }

    func testCommitLoadedContentPublishesOneCoherentSnapshot() {
        let sut = makeSUT()
        let verse = Quran.hafsMadani1405.firstVerse
        let firstTranslation = makeTranslation(id: 1)
        sut.commitLoadedContent(
            verses: [verse],
            translations: [firstTranslation],
            verseTexts: [verse: makeVerseText(translationCount: 1)]
        )

        var snapshots: [[Int]] = []
        let cancellable = sut.$loadedContent
            .dropFirst()
            .sink { content in
                snapshots.append([
                    content.translations.count,
                    content.verseTexts[verse]?.translations.count ?? -1,
                ])
            }

        sut.commitLoadedContent(
            verses: [verse],
            translations: [firstTranslation, makeTranslation(id: 2)],
            verseTexts: [verse: makeVerseText(translationCount: 2)]
        )

        XCTAssertEqual(snapshots, [[2, 2]])
        withExtendedLifetime(cancellable) { }
    }

    override func setUp() {
        super.setUp()
        QuranContentStatePreferences.shared.showArabicInTranslation = true
    }

    override func tearDown() {
        QuranContentStatePreferences.shared.showArabicInTranslation = true
        super.tearDown()
    }

    private func hideArabicText() {
        QuranContentStatePreferences.shared.showArabicInTranslation = false
    }

    private func verseNumbers(in viewModel: ContentTranslationViewModel) -> [TranslationVerseNumber] {
        viewModel.items(quranFont: .uthmanicHafs).compactMap { item in
            guard case .verseNumber(let verseNumber, _) = item else { return nil }
            return verseNumber
        }
    }

    private func suraName(in items: [TranslationItem]) throws -> TranslationSuraName {
        try XCTUnwrap(items.compactMap { item in
            guard case .suraName(let suraName, _) = item else { return nil }
            return suraName
        }.first)
    }

    private func makeSUT(overlayService: VerseOverlayService = .init()) -> ContentTranslationViewModel {
        let unavailableURL = URL(fileURLWithPath: "/tmp/unavailable-quran-translation-test")
        return ContentTranslationViewModel(
            localTranslationsRetriever: .init(databasesURL: unavailableURL),
            dataService: .init(databasesURL: unavailableURL, quranFileURL: unavailableURL),
            overlayService: overlayService
        )
    }

    private func makeTranslation(id: Translation.ID) -> Translation {
        Translation(
            id: id,
            displayName: "Translation \(id)",
            translator: nil,
            translatorForeign: nil,
            fileURL: URL(string: "https://example.com/translation-\(id).zip")!,
            fileName: "translation-\(id).db",
            languageCode: "en",
            version: 1
        )
    }

    /// The ids of the rows of verses, without the page header and footer.
    private func verseIds(in viewModel: ContentTranslationViewModel) -> [TranslationItemId] {
        viewModel.items(quranFont: .uthmanicHafs).map(\.id).filter { $0.ayah != nil }
    }

    private func makeVerseText(translationCount: Int) -> VerseText {
        makeVerseText((0 ..< translationCount).map { "Translation \($0)" })
    }

    private func makeVerseText(_ texts: [String]) -> VerseText {
        VerseText(
            arabicText: "Arabic",
            translations: texts.map { .string(makeTranslationString($0)) },
            arabicPrefix: [],
            arabicSuffix: []
        )
    }

    private func makeTranslationString(_ text: String) -> TranslationString {
        TranslationString(text: text, quranRanges: [], footnoteRanges: [], footnotes: [])
    }
}

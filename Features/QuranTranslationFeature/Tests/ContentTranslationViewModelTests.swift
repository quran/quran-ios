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
        XCTAssertEqual(annotatedItem.verseNumber.annotations, [.note, .collection, .readingBookmark(.teal), .readingBookmark(.orange)])
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

        let items = sut.items(quranFont: .uthmanicHafs)
        let verseNumber = try XCTUnwrap(verseNumbers(in: items).first)

        XCTAssertEqual(try textChunk(in: items).verseNumber, verseNumber)
        XCTAssertEqual(verseNumber.annotations, [.note])
    }

    private func verseNumberItem(in viewModel: ContentTranslationViewModel) throws -> TranslationVerseHeader {
        try XCTUnwrap(verseHeaders(in: viewModel.items(quranFont: .uthmanicHafs)).first)
    }
    #endif

    func testArabicTextSharesTheVerseNumberRow() throws {
        let verse = Quran.hafsMadani1405.firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(translationCount: 1)]
        )

        let items = sut.items(quranFont: .uthmanicHafs)
        let header = try XCTUnwrap(verseHeaders(in: items).first)

        XCTAssertEqual(header.id, .verseNumber(verse))
        XCTAssertEqual(header.arabicText.verse, verse)
        XCTAssertEqual(verseNumbers(in: items).map(\.verse), [verse])
        XCTAssertNil(try textChunk(in: items).verseNumber)
    }

    func testHiddenArabicTextStartsFirstTranslationWithVerseNumber() throws {
        hideArabicText()
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1), makeTranslation(id: 2)],
            verseTexts: [verse: makeVerseText(translationCount: 2)]
        )

        let items = sut.items(quranFont: .uthmanicHafs)
        let chunks = textChunks(in: items)

        XCTAssertTrue(verseHeaders(in: items).isEmpty)
        XCTAssertEqual(chunks.map(\.verseNumber?.verse), [verse, nil])
        XCTAssertEqual(verseNumbers(in: items).map(\.verse), [verse])
        XCTAssertEqual(try suraName(in: items).showsBesmAllah, false)
    }

    func testHiddenArabicTextStartsReferenceWithVerseNumber() throws {
        hideArabicText()
        let verse = Quran.hafsMadani1405.suras[1].verses[1]
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1), makeTranslation(id: 2)],
            verseTexts: [verse: makeVerseText([.reference(verse.previous!), .string(makeTranslationString("Translation"))])]
        )

        let items = sut.items(quranFont: .uthmanicHafs)
        let reference = try XCTUnwrap(items.compactMap { item -> TranslationReferenceVerse? in
            guard case .translationReferenceVerse(let reference, _) = item else { return nil }
            return reference
        }.first)

        XCTAssertEqual(reference.verseNumber?.verse, verse)
        XCTAssertNil(try textChunk(in: items).verseNumber)
        XCTAssertEqual(verseNumbers(in: items).map(\.verse), [verse])
    }

    func testHiddenArabicTextHidesPlaceholderBesideAnotherTranslation() throws {
        hideArabicText()
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1), makeTranslation(id: 2)],
            verseTexts: [verse: makeVerseText(["...", "Translation"])]
        )

        let items = sut.items(quranFont: .uthmanicHafs)
        let chunk = try textChunk(in: items)

        XCTAssertEqual(textChunks(in: items).map(\.translation.id), [2])
        XCTAssertEqual(chunk.verseNumber?.verse, verse)
        XCTAssertFalse(items.contains { $0.id == .translator(verse, translationId: 1) })
        XCTAssertTrue(items.contains { $0.id == .translator(verse, translationId: 2) })
    }

    func testHiddenArabicTextHidesPlaceholderBesideAReference() throws {
        hideArabicText()
        let verse = Quran.hafsMadani1405.suras[1].verses[1]
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1), makeTranslation(id: 2)],
            verseTexts: [verse: makeVerseText([.string(makeTranslationString("...")), .reference(verse.previous!)])]
        )

        let items = sut.items(quranFont: .uthmanicHafs)
        let reference = try XCTUnwrap(items.compactMap { item -> TranslationReferenceVerse? in
            guard case .translationReferenceVerse(let reference, _) = item else { return nil }
            return reference
        }.first)

        XCTAssertEqual(items.map(\.id).filter { $0.ayah != nil }, [
            .translationReference(verse, translationId: 2),
            .translator(verse, translationId: 2),
        ])
        XCTAssertEqual(reference.verseNumber?.verse, verse)
    }

    func testHiddenArabicTextKeepsVerseNumberOnFirstChunkAfterReadMore() {
        hideArabicText()
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let longText = Array(repeating: "Lorem ipsum dolor sit amet.", count: 100).joined(separator: " ")
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1), makeTranslation(id: 2)],
            verseTexts: [verse: makeVerseText(["...", longText])]
        )
        XCTAssertEqual(textChunks(in: sut.items(quranFont: .uthmanicHafs)).count, 1)

        sut.openURL(.readMore(translationId: 2, sura: verse.sura.suraNumber, ayah: verse.ayah))

        let chunks = textChunks(in: sut.items(quranFont: .uthmanicHafs))
        XCTAssertGreaterThan(chunks.count, 2)
        XCTAssertEqual(chunks.map(\.chunkIndex), Array(0 ..< chunks.count))
        XCTAssertEqual(chunks.map(\.verseNumber?.verse), [verse] + Array(repeating: nil, count: chunks.count - 1))
    }

    func testHiddenArabicTextKeepsPlaceholderWhenItIsTheVerseOnlyText() throws {
        hideArabicText()
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(["..."])]
        )

        let items = sut.items(quranFont: .uthmanicHafs)

        XCTAssertEqual(items.map(\.id).filter { $0.ayah != nil }, [
            .suraName(verse.sura),
            .translationTextChunk(verse, translationId: 1, chunkIndex: 0),
        ])
        XCTAssertEqual(try textChunk(in: items).verseNumber?.verse, verse)
        XCTAssertTrue(verseHeaders(in: items).isEmpty)
        XCTAssertEqual(try suraName(in: items).showsBesmAllah, false)
    }

    func testHiddenArabicTextKeepsAllPlaceholdersWithTheirTranslatorNames() {
        hideArabicText()
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1), makeTranslation(id: 2)],
            verseTexts: [verse: makeVerseText(["...", "…"])]
        )

        let items = sut.items(quranFont: .uthmanicHafs)

        XCTAssertEqual(items.map(\.id).filter { $0.ayah != nil }, [
            .suraName(verse.sura),
            .translationTextChunk(verse, translationId: 1, chunkIndex: 0),
            .translator(verse, translationId: 1),
            .translationTextChunk(verse, translationId: 2, chunkIndex: 0),
            .translator(verse, translationId: 2),
        ])
        XCTAssertEqual(textChunks(in: items).map(\.verseNumber?.verse), [verse, nil])
    }

    func testPlaceholderIsHiddenBesideTheArabicText() throws {
        let verse = Quran.hafsMadani1405.suras[1].firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(["..."])]
        )

        let items = sut.items(quranFont: .uthmanicHafs)

        XCTAssertEqual(items.map(\.id).filter { $0.ayah != nil }, [.suraName(verse.sura), .verseNumber(verse)])
        XCTAssertEqual(try XCTUnwrap(verseHeaders(in: items).first).arabicText.verse, verse)
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

        let verseIds = sut.items(quranFont: .uthmanicHafs).map(\.id).filter { $0.ayah != nil }

        XCTAssertEqual(verseIds, [
            .suraName(verse.sura),
            .verseNumber(verse),
            .translationTextChunk(verse, translationId: 1, chunkIndex: 0),
            .translator(verse, translationId: 1),
        ])
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

        XCTAssertEqual(verseHeaders(in: items).map(\.arabicText.verse), [verse])
        XCTAssertEqual(try suraName(in: items).showsBesmAllah, true)
    }

    func testArabicTextVisibilityKeepsTheVerseAnchoredToItsFirstRow() throws {
        let verse = Quran.hafsMadani1405.firstVerse
        let sut = makeSUT()
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(translationCount: 1)]
        )
        XCTAssertEqual(verseHeaders(in: sut.items(quranFont: .uthmanicHafs)).map(\.verse), [verse])

        hideArabicText()

        let items = sut.items(quranFont: .uthmanicHafs)
        XCTAssertFalse(sut.showArabicText)
        XCTAssertTrue(verseHeaders(in: items).isEmpty)
        XCTAssertEqual(try textChunk(in: items).verseNumber?.verse, verse)
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

    private func verseHeaders(in items: [TranslationItem]) -> [TranslationVerseHeader] {
        items.compactMap { item in
            guard case .verseHeader(let verseHeader, _) = item else { return nil }
            return verseHeader
        }
    }

    private func textChunks(in items: [TranslationItem]) -> [TranslationTextChunk] {
        items.compactMap { item in
            guard case .translationTextChunk(let chunk, _) = item else { return nil }
            return chunk
        }
    }

    private func textChunk(in items: [TranslationItem]) throws -> TranslationTextChunk {
        try XCTUnwrap(textChunks(in: items).first)
    }

    /// Every verse-number capsule, wherever it is shown.
    private func verseNumbers(in items: [TranslationItem]) -> [TranslationVerseNumber] {
        items.compactMap { item in
            switch item {
            case .verseHeader(let verseHeader, _): verseHeader.verseNumber
            case .translationTextChunk(let chunk, _): chunk.verseNumber
            case .translationReferenceVerse(let reference, _): reference.verseNumber
            default: nil
            }
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

    private func makeVerseText(translationCount: Int) -> VerseText {
        makeVerseText((0 ..< translationCount).map { "Translation \($0)" })
    }

    private func makeVerseText(_ texts: [String]) -> VerseText {
        makeVerseText(texts.map { .string(makeTranslationString($0)) })
    }

    private func makeVerseText(_ translations: [TranslationText]) -> VerseText {
        VerseText(
            arabicText: "Arabic",
            translations: translations,
            arabicPrefix: [],
            arabicSuffix: []
        )
    }

    private func makeTranslationString(_ text: String) -> TranslationString {
        TranslationString(text: text, quranRanges: [], footnoteRanges: [], footnotes: [])
    }
}

//
//  ContentTranslationViewModelTests.swift
//

import AnnotationsService
import Combine
import QuranAnnotations
import QuranKit
import QuranText
import ReadingService
import XCTest
@testable import QuranTranslationFeature

@MainActor
final class ContentTranslationViewModelTests: XCTestCase {
    #if QURAN_SYNC
    func testArabicItemsIncludeLiveAnnotationsAndRemoveClearedBadges() throws {
        let verse = Quran.hafsMadani1405.firstVerse
        let service = VerseOverlayService()
        let sut = makeSUT(overlayService: service)
        sut.verses = [verse]
        sut.commitLoadedContent(
            verses: [verse],
            translations: [makeTranslation(id: 1)],
            verseTexts: [verse: makeVerseText(translationCount: 1)]
        )
        let originalItem = try arabicItem(in: sut)

        service.overlays.notedVerses = [verse]
        service.overlays.collectionVerses = [verse]
        service.overlays.readingBookmarks = [
            .init(id: "coral", slot: .coral, placement: .ayah(verse), modifiedOn: .distantPast),
            .init(id: "teal", slot: .teal, placement: .ayah(verse), modifiedOn: .distantPast),
            .init(id: "page", slot: .indigo, placement: .page(verse.page), modifiedOn: .distantPast),
        ]

        let annotatedItem = try arabicItem(in: sut)
        XCTAssertEqual(annotatedItem.annotations, [.note, .collection, .readingBookmark(.coral), .readingBookmark(.teal)])
        XCTAssertEqual(annotatedItem.id, originalItem.id)
        XCTAssertNotEqual(annotatedItem, originalItem)

        service.overlays.notedVerses = []
        service.overlays.collectionVerses = []
        service.overlays.readingBookmarks = []

        XCTAssertEqual(try arabicItem(in: sut), originalItem)
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

    private func arabicItem(in viewModel: ContentTranslationViewModel) throws -> TranslationArabicText {
        try XCTUnwrap(viewModel.items(quranFont: .uthmanicHafs).compactMap { item in
            guard case .arabicText(let text, _) = item else { return nil }
            return text
        }.first)
    }
    #endif

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
        VerseText(
            arabicText: "Arabic",
            translations: (0 ..< translationCount).map { index in
                .string(.init(
                    text: "Translation \(index)",
                    quranRanges: [],
                    footnoteRanges: [],
                    footnotes: []
                ))
            },
            arabicPrefix: [],
            arabicSuffix: []
        )
    }
}

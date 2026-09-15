//
//  ContentTranslationViewModelTests.swift
//

import AnnotationsService
import Combine
import QuranKit
import QuranText
import ReadingService
import XCTest
@testable import QuranTranslationFeature

@MainActor
final class ContentTranslationViewModelTests: XCTestCase {
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

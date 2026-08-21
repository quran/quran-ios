//
//  ContentTranslationViewModelTests.swift
//

import Combine
import NoorUI
import QuranKit
import QuranText
import XCTest
@testable import QuranTranslationFeature

@MainActor
final class ContentTranslationViewModelTests: XCTestCase {
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

    func testQuranFontUpdatesFromSource() {
        let updates = PassthroughSubject<QuranFont, Never>()
        let sut = makeSUT(quranFontSource: QuranFontSource(current: { .uthmanicHafs }, updates: updates))

        updates.send(.indoPak)

        XCTAssertEqual(sut.quranFont, .indoPak)
    }

    private func makeSUT(
        quranFontSource: QuranFontSource = QuranFontSource(.uthmanicHafs)
    ) -> ContentTranslationViewModel {
        let unavailableURL = URL(fileURLWithPath: "/tmp/unavailable-quran-translation-test")
        return ContentTranslationViewModel(
            localTranslationsRetriever: .init(databasesURL: unavailableURL),
            dataService: .init(databasesURL: unavailableURL, quranFileURL: unavailableURL),
            highlightsService: .init(),
            quranFontSource: quranFontSource
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

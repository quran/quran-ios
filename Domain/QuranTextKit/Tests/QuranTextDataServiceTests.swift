//
//  QuranTextDataServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-18.
//

import QuranKit
import QuranText
@testable import QuranTextKit
import SystemDependenciesFake
@testable import TranslationService
import TranslationServiceFake
import VerseTextPersistence
import XCTest

final class QuranTextDataServiceTests: XCTestCase {
    private var textService: QuranTextDataService!
    private var localTranslationsFake: LocalTranslationsFake!
    private let quran = Quran.hafsMadani1405

    private let translations = [
        TestData.khanTranslation,
        TestData.sahihTranslation,
    ]

    override func setUp() async throws {
        try await super.setUp()

        localTranslationsFake = LocalTranslationsFake()
        let localtranslationsRetriever = localTranslationsFake.retriever
        let persistence = GRDBQuranVerseTextPersistence(mode: .arabic, fileURL: TestData.quranTextURL)
        textService = QuranTextDataService(localTranslationRetriever: localtranslationsRetriever,
                                           arabicPersistence: persistence,
                                           translationsPersistenceBuilder: TestData.translationsPersistenceBuilder)

        let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
        selectedTranslationsPreferences.selectedTranslations = translations.map(\.id)

        try await localTranslationsFake.setTranslations(translations)
    }

    override func tearDown() {
        super.tearDown()
        localTranslationsFake.tearDown()
        localTranslationsFake = nil
        textService = nil
    }

    func testArabicNoTranslation() async throws {
        let tests = [
            [quran.suras[0].verses[0]],
            [quran.suras[0].verses[1]],
            [quran.suras[0].verses[1], quran.suras[0].verses[2]],
            [quran.suras[1].verses[0]],
        ]
        for verses in tests {
            let versesText = try await textService.textForVerses(verses, translations: [])

            let expectedVerses = verses.map {
                VerseText(arabicText: TestData.quranTextAt($0),
                          translations: [],
                          arabicPrefix: $0 == quran.suras[1].verses[0] ? [TestData.quranTextAt(quran.firstVerse)] : [],
                          arabicSuffix: [])
            }
            let expected = TranslatedVerses(translations: [], verses: expectedVerses)
            XCTAssertEqual(expected, versesText)
        }
    }

    func testWithTranslations() async throws {
        let tests = [
            [quran.suras[0].verses[1]],
            [quran.suras[0].verses[1], quran.suras[0].verses[2]],
        ]
        for verses in tests {
            let versesText = try await textService.textForVerses(verses)

            let expectedVerses = verses.map { verse in
                VerseText(arabicText: TestData.quranTextAt(verse),
                          translations: translations.map {
                              .string(TranslationString(text: TestData.translationTextAt($0, verse), quranRanges: [], footerRanges: []))
                          },
                          arabicPrefix: [],
                          arabicSuffix: [])
            }
            let expected = TranslatedVerses(translations: translations, verses: expectedVerses)
            XCTAssertEqual(expected, versesText)
        }
    }

    func testTranslationWithFooterAndVerses() async throws {
        let translations = [TestData.khanTranslation]
        try await localTranslationsFake.setTranslations(translations)

        let verse = quran.suras[0].verses[5]
        let versesText = try await textService.textForVerses([verse])

        let translationText = TestData.translationTextAt(translations[0], verse)
        let string = TranslationString(text: translationText,
                                       quranRanges: [translationText.nsRange(of: "{ABC}"), translationText.nsRange(of: "{DE}")],
                                       footerRanges: [translationText.nsRange(of: "[[Footer1]]"), translationText.nsRange(of: "[[Footer2]]")])
        let expectedVerse = VerseText(arabicText: TestData.quranTextAt(verse),
                                      translations: [.string(string)],
                                      arabicPrefix: [],
                                      arabicSuffix: [])
        let expected = TranslatedVerses(translations: translations, verses: [expectedVerse])
        XCTAssertEqual(expected, versesText)
    }
}

extension String {
    func nsRange(of substring: String) -> NSRange {
        (self as NSString).range(of: substring)
    }
}

//
//  QuranTextDataServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-18.
//

import PromiseKit
import QuranKit
@testable import QuranTextKit
import TranslationService
import XCTest

final class QuranTextDataServiceTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    private var textService: QuranTextDataService!
    private var mockTranslationsRetriever: LocalTranslationsRetrieverMock!
    private let quran = Quran.madani

    private let translations = [
        TestData.khanTranslation,
        TestData.sahihTranslation,
    ]

    override func setUp() {
        super.setUp()
        mockTranslationsRetriever = LocalTranslationsRetrieverMock()
        let persistence = SQLiteQuranVerseTextPersistence(quran: quran, mode: .arabic, fileURL: TestData.quranTextURL)
        textService = QuranTextDataService(localTranslationRetriever: mockTranslationsRetriever,
                                           arabicPersistence: persistence,
                                           translationsPersistenceBuilder: TestData.translationsPersistenceBuilder)

        let selectedTranslationsPreferences = DefaultsSelectedTranslationsPreferences(userDefaults: .standard)
        selectedTranslationsPreferences.selectedTranslations = translations.map(\.id)

        mockTranslationsRetriever.getLocalTranslationsHandler = {
            .value(self.translations)
        }
    }

    func testArabicNoTranslation() throws {
        let tests = [
            [quran.suras[0].verses[0]],
            [quran.suras[0].verses[1]],
            [quran.suras[0].verses[1], quran.suras[0].verses[2]],
            [quran.suras[1].verses[0]],
        ]
        for verses in tests {
            let versesText = try wait(for: textService.textForVerses(verses, translations: []))

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

    func testWithTranslations() throws {
        let tests = [
            [quran.suras[0].verses[1]],
            [quran.suras[0].verses[1], quran.suras[0].verses[2]],
        ]
        for verses in tests {
            let versesText = try wait(for: textService.textForVerses(verses))

            let expectedVerses = verses.map { verse in
                VerseText(arabicText: TestData.quranTextAt(verse),
                          translations: translations.map {
                              .string(TestData.translationTextAt($0, verse))
                          },
                          arabicPrefix: [],
                          arabicSuffix: [])
            }
            let expected = TranslatedVerses(translations: translations, verses: expectedVerses)
            XCTAssertEqual(expected, versesText)
        }
    }
}

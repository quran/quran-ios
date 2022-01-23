//
//  ShareableVerseTextRetrieverTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-19.
//

import PromiseKit
import QuranKit
@testable import QuranTextKit
import TestUtilities
import TranslationService
import XCTest

final class ShareableVerseTextRetrieverTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    private var shareableTextRetriever: ShareableVerseTextRetriever!
    private var textService: QuranTextDataService!
    private var mockTranslationsRetriever: LocalTranslationsRetrieverMock!
    private let quran = Quran.madani
    let statePreferences = DefaultsQuranContentStatePreferences(userDefaults: .standard)

    private let translations = [
        TestData.khanTranslation,
        TestData.sahihTranslation,
    ]

    override func setUp() {
        super.setUp()
        mockTranslationsRetriever = LocalTranslationsRetrieverMock()
        let persistence = SQLiteQuranVerseTextPersistence(quran: quran, mode: .share, fileURL: TestData.quranTextURL)
        textService = QuranTextDataService(localTranslationRetriever: mockTranslationsRetriever,
                                           arabicPersistence: persistence,
                                           translationsPersistenceBuilder: TestData.translationsPersistenceBuilder)

        shareableTextRetriever = ShareableVerseTextRetriever(
            preferences: statePreferences,
            textService: textService,
            shareableVersePersistence: persistence
        )

        let selectedTranslationsPreferences = DefaultsSelectedTranslationsPreferences(userDefaults: .standard)
        selectedTranslationsPreferences.selectedTranslations = translations.map(\.id)

        mockTranslationsRetriever.getLocalTranslationsHandler = {
            .value(self.translations)
        }
    }

    func testShareArabicText() throws {
        statePreferences.quranMode = .arabic
        let tests = [
            (verses: [quran.suras[0].verses[2]],
             result: ["ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ٣ ﴾",
                      "",
                      "Al-Fatihah, Ayah 3"]),
            (verses: [quran.suras[0].verses[0], quran.suras[0].verses[1], quran.suras[0].verses[2]],
             result: ["بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ١ ﴾ ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَـٰلَمِینَ﴿ ٢ ﴾ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ٣ ﴾",
                      "",
                      "Al-Fatihah, Ayah 1 - Al-Fatihah, Ayah 3"]),
        ]
        for test in tests {
            let versesText = wait(for: shareableTextRetriever.textForVerses(test.verses, page: quran.pages[0]))
            XCTAssertEqual(test.result, versesText)
        }
    }

    func testShareTranslationText() throws {
        statePreferences.quranMode = .translation

        let tests = [
            (verses: [quran.suras[0].verses[2]],
             result: ["ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ٣ ﴾",
                      "",
                      "• Khan & Hilai:",
                      TestData.translationTextAt(translations[0], quran.suras[0].verses[2]),
                      "",
                      "• Sahih International:",
                      TestData.translationTextAt(translations[1], quran.suras[0].verses[2]),
                      "",
                      "Al-Fatihah, Ayah 3"]),
            (verses: [quran.suras[0].verses[0], quran.suras[0].verses[1], quran.suras[0].verses[2]],
             result: ["بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ١ ﴾ ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَـٰلَمِینَ﴿ ٢ ﴾ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ٣ ﴾",
                      "",
                      "• Khan & Hilai:",
                      TestData.translationTextAt(translations[0], quran.suras[0].verses[0]),
                      TestData.translationTextAt(translations[0], quran.suras[0].verses[1]),
                      TestData.translationTextAt(translations[0], quran.suras[0].verses[2]),
                      "",
                      "• Sahih International:",
                      TestData.translationTextAt(translations[1], quran.suras[0].verses[0]),
                      TestData.translationTextAt(translations[1], quran.suras[0].verses[1]),
                      TestData.translationTextAt(translations[1], quran.suras[0].verses[2]),
                      "",
                      "Al-Fatihah, Ayah 1 - Al-Fatihah, Ayah 3"]),
        ]
        for test in tests {
            let versesText = wait(for: shareableTextRetriever.textForVerses(test.verses, page: quran.pages[0]))
            XCTAssertEqual(test.result, versesText)
        }
    }
}

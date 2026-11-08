//
//  ShareableVerseTextRetrieverTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-19.
//

import QuranKit
import TranslationService
import TranslationServiceFake
import VerseTextPersistence
import XCTest
@testable import QuranTextKit

final class ShareableVerseTextRetrieverTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()

        localTranslationsFake = LocalTranslationsFake()
        let localtranslationsRetriever = localTranslationsFake.retriever
        let persistence = GRDBQuranVerseTextPersistence(mode: .share, fileURL: TestData.quranTextURL)
        textService = QuranTextDataService(
            localTranslationRetriever: localtranslationsRetriever,
            arabicPersistence: persistence,
            translationsPersistenceBuilder: TestData.translationsPersistenceBuilder
        )

        shareableTextRetriever = ShareableVerseTextRetriever(
            textService: textService,
            shareableVersePersistence: persistence,
            localTranslationsRetriever: localtranslationsRetriever
        )

        let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
        selectedTranslationsPreferences.selectedTranslationIds = translations.map(\.id)

        try await localTranslationsFake.setTranslations(translations)
    }

    override func tearDown() {
        super.tearDown()
        localTranslationsFake.tearDown()
        localTranslationsFake = nil
        textService = nil
        shareableTextRetriever = nil
    }

    func testShareArabicText() async throws {
        statePreferences.quranMode = .arabic
        let tests = [
            (
                verses: [quran.suras[0].verses[2]],
                result: ["\(rightToLeftMark)ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ٣ ﴾\(endMark)",
                         "",
                         "Al-Fātihah 1:3"]
            ),
            (
                verses: [quran.suras[0].verses[0], quran.suras[0].verses[1], quran.suras[0].verses[2]],
                result: ["\(rightToLeftMark)بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ١ ﴾\(endMark) \(rightToLeftMark)ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَـٰلَمِینَ﴿ ٢ ﴾\(endMark) \(rightToLeftMark)ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ٣ ﴾\(endMark)",
                         "",
                         "Al-Fātihah 1:1–3"]
            ),
        ]
        for test in tests {
            let versesText = try await shareableTextRetriever.textForVerses(test.verses)
            XCTAssertEqual(test.result, versesText)
        }
    }

    func testShareArabicText_summarizesEachRunOfConsecutiveVerses() async throws {
        statePreferences.quranMode = .arabic
        let verses = quran.suras[0].verses
        let versesText = try await shareableTextRetriever.textForVerses([verses[0], verses[1], verses[3]])

        XCTAssertEqual(versesText.last, "Al-Fātihah 1:1–2; Al-Fātihah 1:4")
    }

    func testShareArabicText_namesAWholeSuraAndBothEndsAcrossSuras() async throws {
        statePreferences.quranMode = .arabic
        let fatihah = quran.suras[0].verses
        let wholeSura = try await shareableTextRetriever.textForVerses(fatihah)
        let acrossSuras = try await shareableTextRetriever.textForVerses([fatihah[6], quran.suras[1].verses[0]])

        XCTAssertEqual(wholeSura.last, "Al-Fātihah")
        XCTAssertEqual(acrossSuras.last, "Al-Fātihah 1:7 – Al-Baqarah 2:1")
    }

    func testShareTranslationText() async throws {
        statePreferences.quranMode = .translation

        let tests = [
            (
                verses: [quran.suras[0].verses[2]],
                result: ["\(rightToLeftMark)ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ٣ ﴾\(endMark)",
                         "",
                         "• Khan & Hilai:",
                         TestData.translationTextAt(translations[0], quran.suras[0].verses[2]),
                         "",
                         "• Sahih International:",
                         TestData.translationTextAt(translations[1], quran.suras[0].verses[2]),
                         "",
                         "Al-Fātihah 1:3"]
            ),
            (
                verses: [quran.suras[0].verses[0], quran.suras[0].verses[1], quran.suras[0].verses[2]],
                result: ["\(rightToLeftMark)بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ١ ﴾\(endMark) \(rightToLeftMark)ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَـٰلَمِینَ﴿ ٢ ﴾\(endMark) \(rightToLeftMark)ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ﴿ ٣ ﴾\(endMark)",
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
                         "Al-Fātihah 1:1–3"]
            ),
        ]
        for test in tests {
            let versesText = try await shareableTextRetriever.textForVerses(test.verses)
            XCTAssertEqual(test.result, versesText)
        }
    }

    func testShareTranslationTextReferenceVerse() async throws {
        statePreferences.quranMode = .translation

        try await localTranslationsFake.setTranslations([TestData.khanTranslation])

        let numberReference = try await shareableTextRetriever.textForVerses([quran.suras[1].verses[49]])
        XCTAssertEqual(numberReference, ["\(rightToLeftMark)وَإِذۡ فَرَقۡنَا بِكُمُ ٱلۡبَحۡرَ فَأَنجَیۡنَـٰكُمۡ وَأَغۡرَقۡنَاۤ ءَالَ فِرۡعَوۡنَ وَأَنتُمۡ تَنظُرُونَ﴿ ٥٠ ﴾\(endMark)",
                                         "",
                                         "• Khan & Hilai:",
                                         "See ayah 38.",
                                         "",
                                         "Al-Baqarah 2:50"])

        let verseSavedAsTextReference = try await shareableTextRetriever.textForVerses([quran.suras[1].verses[50]])
        XCTAssertEqual(verseSavedAsTextReference, ["\(rightToLeftMark)وَإِذۡ وَ ٰ⁠عَدۡنَا مُوسَىٰۤ أَرۡبَعِینَ لَیۡلَةࣰ ثُمَّ ٱتَّخَذۡتُمُ ٱلۡعِجۡلَ مِنۢ بَعۡدِهِۦ وَأَنتُمۡ ظَـٰلِمُونَ﴿ ٥١ ﴾\(endMark)",
                                                   "",
                                                   "• Khan & Hilai:",
                                                   "See ayah 38.",
                                                   "",
                                                   "Al-Baqarah 2:51"])
    }

    // MARK: Private

    private var shareableTextRetriever: ShareableVerseTextRetriever!
    private var textService: QuranTextDataService!
    private var localTranslationsFake: LocalTranslationsFake!
    private let quran = Quran.hafsMadani1405
    private let statePreferences = QuranContentStatePreferences.shared
    private let rightToLeftMark = "\u{202B}"
    private let endMark = "\u{202C}"
    private let translations = [
        TestData.khanTranslation,
        TestData.sahihTranslation,
    ]
}

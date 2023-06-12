//
//  TestData.swift
//
//
//  Created by Mohamed Afifi on 2021-12-19.
//

import Foundation
import QuranKit
import QuranText
@testable import QuranTextKit
import TestResources
import TranslationServiceFake

struct TestData {
    static let khanTranslation = TranslationTestData.khanTranslation
    static let sahihTranslation = TranslationTestData.sahihTranslation

    static let translationsPersistenceBuilder = { (translation: Translation) -> TranslationVerseTextPersistence in
        let url = TestResources.resourceURL(translation.fileName)
        return GRDBTranslationVerseTextPersistence(fileURL: url)
    }

    static let quranTextURL = TestResources.resourceURL("quran.ar.uthmani.v2.db")

    static func quranTextAt(_ verse: AyahNumber) -> String {
        quranText[verse] ?? "Not added to TestData.swift"
    }

    static func translationTextAt(_ translation: Translation, _ verse: AyahNumber) -> String {
        let translationTextDict = translationText[translation]!
        return translationTextDict[verse]!
    }
}

private let quran = Quran.hafsMadani1405

private let quranText: [AyahNumber: String] = [
    quran.suras[0].verses[0]: "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ",
    quran.suras[0].verses[1]: "ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ",
    quran.suras[0].verses[5]: "ٱهۡدِنَا ٱلصِّرَٰطَ ٱلۡمُسۡتَقِيمَ",
    quran.suras[0].verses[2]: "ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ",
    quran.suras[1].verses[0]: "الٓمٓ",
]

private let translationText: [Translation: [AyahNumber: String]] = [
    TestData.khanTranslation: [
        quran.suras[0].verses[0]: "In the Name of Allah, the Most Beneficent, the Most Merciful.",
        quran.suras[0].verses[1]: "All the praises and thanks be to Allah, the Lord of the 'Alamin (mankind, jinns and all that exists).",
        quran.suras[0].verses[2]: "The Most Beneficent, the Most Merciful.",
        quran.suras[0].verses[5]: "Guide us to the Straight Way.  {ABC} [[Footer1]] {DE} [[Footer2]] FG",
    ],
    TestData.sahihTranslation: [
        quran.suras[0].verses[0]: "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
        quran.suras[0].verses[1]: "[All] praise is [due] to Allah, Lord of the worlds -",
        quran.suras[0].verses[2]: "The Entirely Merciful, the Especially Merciful,",
    ],
]

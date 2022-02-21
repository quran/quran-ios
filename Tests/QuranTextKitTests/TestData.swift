//
//  TestData.swift
//
//
//  Created by Mohamed Afifi on 2021-12-19.
//

import Foundation
import QuranKit
import QuranMadaniData
@testable import QuranTextKit
@testable import TranslationService

struct TestData {
    static let khanTranslation = Translation(id: 1, displayName: "",
                                             translator: "",
                                             translatorForeign: "Khan & Hilai",
                                             fileURL: URL(validURL: "a"),
                                             fileName: "quran.en.khanhilali.db",
                                             languageCode: "",
                                             version: 1,
                                             installedVersion: 1)

    static let sahihTranslation = Translation(id: 2, displayName: "",
                                              translator: "",
                                              translatorForeign: "Sahih International",
                                              fileURL: URL(validURL: "a"),
                                              fileName: "quran.ensi.db",
                                              languageCode: "",
                                              version: 1,
                                              installedVersion: 1)

    static let translationsPersistenceBuilder = { (translation: Translation, quran: Quran) -> TranslationVerseTextPersistence in
        let url = resourceURL(translation.fileName)
        return SQLiteTranslationVerseTextPersistence(fileURL: url, quran: quran)
    }

    static let quranTextURL = QuranMadaniData.quranUthmaniV2Database

    static func resourceURL(_ path: String) -> URL {
        let components = path.components(separatedBy: ".")
        let resource = components.dropLast().joined(separator: ".")
        let ext = components.last!
        return Bundle.module.url(forResource: "test_data/" + resource, withExtension: ext)!
    }

    static func quranTextAt(_ verse: AyahNumber) -> String {
        quranText[verse] ?? "Not added to TestData.swift"
    }

    static func translationTextAt(_ translation: Translation, _ verse: AyahNumber) -> String {
        let translationTextDict = translationText[translation]!
        return translationTextDict[verse]!
    }
}

private let quranText: [AyahNumber: String] = [
    Quran.madani.suras[0].verses[0]: "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ",
    Quran.madani.suras[0].verses[1]: "ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ",
    Quran.madani.suras[0].verses[5]: "ٱهۡدِنَا ٱلصِّرَٰطَ ٱلۡمُسۡتَقِيمَ",
    Quran.madani.suras[0].verses[2]: "ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ",
    Quran.madani.suras[1].verses[0]: "الٓمٓ",
]

private let translationText: [Translation: [AyahNumber: String]] = [
    TestData.khanTranslation: [
        Quran.madani.suras[0].verses[0]: "In the Name of Allah, the Most Beneficent, the Most Merciful.",
        Quran.madani.suras[0].verses[1]: "All the praises and thanks be to Allah, the Lord of the 'Alamin (mankind, jinns and all that exists).",
        Quran.madani.suras[0].verses[2]: "The Most Beneficent, the Most Merciful.",
        Quran.madani.suras[0].verses[5]: "Guide us to the Straight Way.  {ABC} [[Footer1]] {DE} [[Footer2]] FG",
    ],
    TestData.sahihTranslation: [
        Quran.madani.suras[0].verses[0]: "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
        Quran.madani.suras[0].verses[1]: "[All] praise is [due] to Allah, Lord of the worlds -",
        Quran.madani.suras[0].verses[2]: "The Entirely Merciful, the Especially Merciful,",
    ],
]

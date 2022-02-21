//
//  QuranTextDataService.swift
//
//
//  Created by Mohamed Afifi on 2021-11-22.
//

import Crashing
import Foundation
import Localization
import PromiseKit
import QuranKit
import TranslationService

public struct QuranTextDataService {
    let localTranslationRetriever: LocalTranslationsRetriever
    let arabicPersistence: VerseTextPersistence
    let translationsPersistenceBuilder: (Translation, Quran) -> TranslationVerseTextPersistence
    let selectedTranslationsPreferences: SelectedTranslationsPreferences

    // regex to detect quran text in translation text
    private static let quranRegex = try! NSRegularExpression(pattern: #"([«{﴿][\s\S]*?[﴾}»])"#)
    // regex to detect footer notes in translation text
    private static let footerRegex = try! NSRegularExpression(pattern: #"\[\[[\s\S]*?]]"#)

    public init(databasesPath: String, quranFileURL: URL) {
        self.init(databasesPath: databasesPath, arabicPersistence: SQLiteQuranVerseTextPersistence(quran: Quran.madani, fileURL: quranFileURL))
    }

    init(databasesPath: String, arabicPersistence: VerseTextPersistence) {
        self.init(localTranslationRetriever: TranslationService.LocalTranslationsRetriever(databasesPath: databasesPath),
                  arabicPersistence: arabicPersistence,
                  translationsPersistenceBuilder: { translation, quran in
                      SQLiteTranslationVerseTextPersistence(fileURL: translation.localURL, quran: quran)
                  })
    }

    init(localTranslationRetriever: LocalTranslationsRetriever,
         arabicPersistence: VerseTextPersistence,
         translationsPersistenceBuilder: @escaping (Translation, Quran) -> TranslationVerseTextPersistence)
    {
        self.localTranslationRetriever = localTranslationRetriever
        self.arabicPersistence = arabicPersistence
        self.translationsPersistenceBuilder = translationsPersistenceBuilder
        selectedTranslationsPreferences = DefaultsSelectedTranslationsPreferences(userDefaults: .standard)
    }

    public func textForVerses(_ verses: [AyahNumber]) -> Promise<TranslatedVerses> {
        textForVerses(verses, translations: localTranslations())
    }

    public func textForVerses(_ verses: [AyahNumber], translations: [Translation]) -> Promise<TranslatedVerses> {
        textForVerses(verses, translations: .value(translations))
    }

    private func textForVerses(_ verses: [AyahNumber], translations: Promise<[Translation]>) -> Promise<TranslatedVerses> {
        // get Arabic text
        // get translations text
        // merge them
        let arabicText = versesArabicText(verses: verses)
        let translations = translations.then {
            fetchTranslationsText(verses: verses, translations: $0)
        }
        return when(fulfilled: translations, arabicText)
            .map { translations, arabic in
                TranslatedVerses(translations: translations.map(\.0),
                                 verses: self.merge(verses: verses, translations: translations, arabic: arabic))
            }
    }

    private func merge(verses: [AyahNumber], translations: [(Translation, [TranslationText])], arabic: [String]) -> [VerseText] {
        var versesText: [VerseText] = []

        for i in 0 ..< verses.count {
            let verse = verses[i]
            let arabicText = arabic[i]
            let ayahTranslations = translations.map { translation, ayahs in
                ayahs[i]
            }
            let prefix = verse == verse.sura.firstVerse && verse.sura.startsWithBesmAllah ? [verse.quran.arabicBesmAllah] : []
            let verseText = VerseText(arabicText: arabicText, translations: ayahTranslations, arabicPrefix: prefix, arabicSuffix: [])
            versesText.append(verseText)
        }
        return versesText
    }

    private func localTranslations() -> Promise<[Translation]> {
        localTranslationRetriever.getLocalTranslations()
            .map { self.selectedTranslations(allTranslations: $0) }
    }

    private func selectedTranslations(allTranslations: [Translation]) -> [Translation] {
        let selected = selectedTranslationsPreferences.selectedTranslations
        let translationsById = allTranslations.flatGroup { $0.id }
        return selected.compactMap { translationsById[$0] }
    }

    private func versesArabicText(verses: [AyahNumber]) -> Promise<[String]> {
        DispatchQueue.global().async(.promise) {
            try self.retrieveArabicText(verses: verses)
        }
    }

    private func retrieveArabicText(verses: [AyahNumber]) throws -> [String] {
        let versesText = try arabicPersistence.textForVerses(verses)
        var verseTextList: [String] = []
        for verse in verses {
            let text = versesText[verse]!
            verseTextList.append(text)
        }
        return verseTextList
    }

    private func fetchTranslationsText(verses: [AyahNumber], translations: [Translation]) -> Promise<[(Translation, [TranslationText])]> {
        when(fulfilled: translations.map { fetchTranslation(verses: verses, translation: $0) })
    }

    private func fetchTranslation(verses: [AyahNumber], translation: Translation) -> Promise<(Translation, [TranslationText])> {
        DispatchQueue.global().async(.promise) {
            let translationPersistence = self.translationsPersistenceBuilder(translation, verses[0].quran)

            var verseTextList: [TranslationText] = []
            do {
                let versesText = try translationPersistence.textForVerses(verses)
                for verse in verses {
                    let text = versesText[verse] ?? .string(l("noAvailableTranslationText"))
                    verseTextList.append(translationText(text))
                }
            } catch {
                crasher.recordError(
                    error,
                    reason: "Issue getting verse \(verses), translation: \(translation.id)"
                )
                let errorText = l("errorInTranslationText")
                for _ in verses {
                    verseTextList.append(.string(TranslationString(text: errorText, quranRanges: [], footerRanges: [])))
                }
            }
            return (translation, verseTextList)
        }
    }

    private func translationText(_ from: RawTranslationText) -> TranslationText {
        switch from {
        case .string(let string):
            return .string(translationString(string))
        case .reference(let verse):
            return .reference(verse)
        }
    }

    private func translationString(_ string: String) -> TranslationString {
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        let quranRanges = ranges(of: Self.quranRegex, in: string, range: range)
        let footerRanges = ranges(of: Self.footerRegex, in: string, range: range)
        return TranslationString(text: string, quranRanges: quranRanges, footerRanges: footerRanges)
    }

    private func ranges(of regex: NSRegularExpression, in string: String, range: NSRange) -> [Range<String.Index>] {
        let matches = regex.matches(in: string, options: [], range: range)
        return matches.map { Range($0.range, in: string)! }
    }
}

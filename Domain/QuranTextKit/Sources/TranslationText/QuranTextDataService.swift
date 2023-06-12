//
//  QuranTextDataService.swift
//
//
//  Created by Mohamed Afifi on 2021-11-22.
//

import Crashing
import Foundation
import Localization
import QuranKit
import QuranText
import TranslationService
import VerseTextPersistence

public struct QuranTextDataService {
    let localTranslationRetriever: LocalTranslationsRetriever
    let arabicPersistence: VerseTextPersistence
    let translationsPersistenceBuilder: (Translation) -> TranslationVerseTextPersistence
    let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared

    // regex to detect quran text in translation text
    private static let quranRegex = try! NSRegularExpression(pattern: #"([«{﴿][\s\S]*?[﴾}»])"#)
    // regex to detect footer notes in translation text
    private static let footerRegex = try! NSRegularExpression(pattern: #"\[\[[\s\S]*?]]"#)

    public init(databasesURL: URL, quranFileURL: URL) {
        self.init(databasesURL: databasesURL, arabicPersistence: GRDBQuranVerseTextPersistence(fileURL: quranFileURL))
    }

    init(databasesURL: URL, arabicPersistence: VerseTextPersistence) {
        self.init(localTranslationRetriever: TranslationService.LocalTranslationsRetriever(databasesURL: databasesURL),
                  arabicPersistence: arabicPersistence,
                  translationsPersistenceBuilder: { translation in
                      GRDBTranslationVerseTextPersistence(fileURL: translation.localURL)
                  })
    }

    init(localTranslationRetriever: LocalTranslationsRetriever,
         arabicPersistence: VerseTextPersistence,
         translationsPersistenceBuilder: @escaping (Translation) -> TranslationVerseTextPersistence)
    {
        self.localTranslationRetriever = localTranslationRetriever
        self.arabicPersistence = arabicPersistence
        self.translationsPersistenceBuilder = translationsPersistenceBuilder
    }

    public func textForVerses(_ verses: [AyahNumber]) async throws -> TranslatedVerses {
        try await textForVerses(verses, translations: { try await localTranslations() })
    }

    public func textForVerses(_ verses: [AyahNumber], translations: [Translation]) async throws -> TranslatedVerses {
        try await textForVerses(verses, translations: { translations })
    }

    private func textForVerses(
        _ verses: [AyahNumber],
        translations: @escaping @Sendable () async throws -> [Translation]
    ) async throws -> TranslatedVerses {
        // get Arabic text
        // get translations text
        // merge them
        async let asyncArabicText = retrieveArabicText(verses: verses)
        async let asyncTranslationsText = Task {
            let localTranslations = try await translations()
            return await fetchTranslationsText(verses: verses, translations: localTranslations)
        }.value

        let (arabicText, translationsText) = try await (asyncArabicText, asyncTranslationsText)
        let translatedVerse = TranslatedVerses(
            translations: translationsText.map(\.0),
            verses: merge(verses: verses, translations: translationsText, arabic: arabicText)
        )
        return translatedVerse
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

    private func localTranslations() async throws -> [Translation] {
        let translations = try await localTranslationRetriever.getLocalTranslations()
        return selectedTranslations(allTranslations: translations)
    }

    private func selectedTranslations(allTranslations: [Translation]) -> [Translation] {
        let selected = selectedTranslationsPreferences.selectedTranslations
        let translationsById = allTranslations.flatGroup { $0.id }
        return selected.compactMap { translationsById[$0] }
    }

    private func retrieveArabicText(verses: [AyahNumber]) async throws -> [String] {
        let versesText = try await arabicPersistence.textForVerses(verses)
        var verseTextList: [String] = []
        for verse in verses {
            let text = versesText[verse]!
            verseTextList.append(text)
        }
        return verseTextList
    }

    private func fetchTranslationsText(
        verses: [AyahNumber],
        translations: [Translation]
    ) async -> [(Translation, [TranslationText])] {
        await withTaskGroup(of: (Translation, [TranslationText]).self) { group in
            for translation in translations {
                group.addTask {
                    await fetchTranslation(verses: verses, translation: translation)
                }
            }
            let result = await group.collect()
            return result.sortedAs(translations.map(\.id), by: \.0.id)
        }
    }

    private func fetchTranslation(
        verses: [AyahNumber],
        translation: Translation
    ) async -> (Translation, [TranslationText]) {
        let translationPersistence = translationsPersistenceBuilder(translation)

        var verseTextList: [TranslationText] = []
        do {
            let versesText = try await translationPersistence.textForVerses(verses)
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

    private func translationText(_ from: TranslationTextPersistenceModel) -> TranslationText {
        switch from {
        case .string(let string):
            return .string(translationString(string))
        case .reference(let verse):
            return .reference(verse)
        }
    }

    private func translationString(_ string: String) -> TranslationString {
        let range = NSRange(string.startIndex ..< string.endIndex, in: string)
        let quranRanges = ranges(of: Self.quranRegex, in: string, range: range)
        let footerRanges = ranges(of: Self.footerRegex, in: string, range: range)
        return TranslationString(text: string, quranRanges: quranRanges, footerRanges: footerRanges)
    }

    private func ranges(of regex: NSRegularExpression, in string: String, range: NSRange) -> [NSRange] {
        let matches = regex.matches(in: string, options: [], range: range)
        return matches.map(\.range)
    }
}

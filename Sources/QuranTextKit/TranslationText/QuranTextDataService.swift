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

private struct AyahText {
    let ayah: AyahNumber
    let text: String
}

public struct QuranTextDataService {
    let localTranslationRetriever: LocalTranslationsRetriever
    let arabicPersistence: VerseTextPersistence
    let translationsPersistenceBuilder: (Translation, Quran) -> VerseTextPersistence
    let selectedTranslationsPreferences: SelectedTranslationsPreferences

    public init(databasesPath: String) {
        self.init(databasesPath: databasesPath, arabicPersistence: SQLiteQuranVerseTextPersistence(quran: Quran.madani))
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
         translationsPersistenceBuilder: @escaping (Translation, Quran) -> VerseTextPersistence)
    {
        self.localTranslationRetriever = localTranslationRetriever
        self.arabicPersistence = arabicPersistence
        self.translationsPersistenceBuilder = translationsPersistenceBuilder
        selectedTranslationsPreferences = DefaultsSelectedTranslationsPreferences(userDefaults: .standard)
    }

    public func textForPage(_ page: Page) -> Promise<PageText> {
        textForVerses(page.verses)
            .map { PageText(page: page, verses: $0) }
    }

    func textForVerses(_ verses: [AyahNumber]) -> Promise<[VerseText]> {
        textForVerses(verses, translations: localTranslations())
    }

    public func textForVerses(_ verses: [AyahNumber], translations: [Translation]) -> Promise<[VerseText]> {
        textForVerses(verses, translations: .value(translations))
    }

    private func textForVerses(_ verses: [AyahNumber], translations: Promise<[Translation]>) -> Promise<[VerseText]> {
        // get Arabic text
        // get translations text
        // merge them
        let arabicText = versesArabicText(verses: verses)
        let translations = translations.then {
            fetchTranslationsText(verses: verses, translations: $0)
        }
        return when(fulfilled: translations, arabicText)
            .map { translations, arabic in
                self.merge(verses: verses, translations: translations, arabic: arabic)
            }
    }

    private func merge(verses: [AyahNumber], translations: [(Translation, [AyahText])], arabic: [AyahText]) -> [VerseText] {
        var versesText: [VerseText] = []

        for i in 0 ..< verses.count {
            let verse = verses[i]
            let arabicText = arabic[i].text
            let ayahTranslations = translations.map { translation, ayahs -> TranslationText in
                TranslationText(translation: translation, text: ayahs[i].text)
            }
            let prefix = verse == verse.sura.firstVerse && verse.sura.startsWithBesmAllah ? [verse.quran.arabicBesmAllah] : []
            let verseText = VerseText(verse: verse, arabicText: arabicText, translations: ayahTranslations, arabicPrefix: prefix, arabicSuffix: [])
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

    private func versesArabicText(verses: [AyahNumber]) -> Promise<[AyahText]> {
        DispatchQueue.global().async(.promise) {
            try self.retrieveArabicText(verses: verses)
        }
    }

    private func retrieveArabicText(verses: [AyahNumber]) throws -> [AyahText] {
        let versesText = try arabicPersistence.textForVerses(verses)
        var verseTextList: [AyahText] = []
        for verse in verses {
            let text = versesText[verse]!
            verseTextList.append(AyahText(ayah: verse, text: text))
        }
        return verseTextList
    }

    private func fetchTranslationsText(verses: [AyahNumber], translations: [Translation]) -> Promise<[(Translation, [AyahText])]> {
        when(fulfilled: translations.map { fetchTranslation(verses: verses, translation: $0) })
    }

    private func fetchTranslation(verses: [AyahNumber], translation: Translation) -> Promise<(Translation, [AyahText])> {
        DispatchQueue.global().async(.promise) {
            let translationPersistence = self.translationsPersistenceBuilder(translation, verses[0].quran)

            var verseTextList: [AyahText] = []
            do {
                let versesText = try translationPersistence.textForVerses(verses)
                for verse in verses {
                    let text: String
                    if let verseText = versesText[verse] {
                        text = verseText
                    } else {
                        text = l("noAvailableTranslationText")
                    }
                    verseTextList.append(AyahText(ayah: verse, text: text))
                }
            } catch {
                crasher.recordError(
                    error,
                    reason: "Issue getting verse \(verses), translation: \(translation.id)"
                )
                let errorText = l("errorInTranslationText")
                for verse in verses {
                    verseTextList.append(AyahText(ayah: verse, text: errorText))
                }
            }
            return (translation, verseTextList)
        }
    }
}

//
//  TranslationPreloadingOperation.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/23/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import PromiseKit

private struct AyahText {
    let ayah: AyahNumber
    let text: String
}

class TranslationPreloadingOperation: AbstractPreloadingOperation<TranslationPage> {

    let page: Int

    private let localTranslationRetriever: LocalTranslationsRetrieverType
    private let arabicPersistence: QuranAyahTextPersistence
    private let translationsPersistenceBuilder: TranslationAyahTextPersistenceBuildable
    private let simplePersistence: SimplePersistence

    init(page: Int,
         localTranslationRetriever: LocalTranslationsRetrieverType,
         arabicPersistence: QuranAyahTextPersistence,
         translationsPersistenceBuilder: TranslationAyahTextPersistenceBuildable,
         simplePersistence: SimplePersistence) {
        self.page = page
        self.simplePersistence = simplePersistence
        self.arabicPersistence = arabicPersistence
        self.localTranslationRetriever = localTranslationRetriever
        self.translationsPersistenceBuilder = translationsPersistenceBuilder
    }

    override func main() {

        // get ayahs in the page
        let range = Quran.range(forPage: page)
        let ayahs = range.getAyahs()

        // get the arabic text
        // get the translations text
        // merge them
        when(fulfilled: Promise.value(ayahs), translationsPromise(ayahs: ayahs), arabicPromise(ayahs: ayahs))
            .map(self.merge(ayahs:translations:arabic:))
            .done(self.fulfill)
            .cauterize(tag: "TranslationPreloadingOperation error")
    }

    private func merge(ayahs: [AyahNumber], translations: [(Translation, [AyahText])], arabic: [AyahText]) -> TranslationPage {
        var verses: [TranslationVerse] = []

        for i in 0..<ayahs.count {
            let ayah = ayahs[i]
            let arabicText = arabic[i].text
            let ayahTranslations = translations.map { (translation, ayahs) -> TranslationText in
                let text = ayahs[i].text
                let isLongText = text.count >= 300
                return TranslationText(translation: translation, text: text, isLongText: isLongText)
            }
            let prefix = ayah.startsWithBesmallah ? [Quran.arabicBasmAllah] : []
            let verse = TranslationVerse(ayah: ayah, arabicText: arabicText, translations: ayahTranslations, arabicPrefix: prefix, arabicSuffix: [])
            verses.append(verse)
        }

        let fontSize = simplePersistence.fontSize
        let theme = simplePersistence.theme
        return TranslationPage(pageNumber: page, verses: verses, fontSize: fontSize, theme: theme)
    }

    private func translationsPromise(ayahs: [AyahNumber]) -> Promise<[(Translation, [AyahText])]> {
        return localTranslationRetriever
            .getLocalTranslations()
            .map(selectedTranslations(allTranslations:))
            .map { self.retrieveAllTranslations(ayahs: ayahs, translations: $0) }
    }

    private func selectedTranslations(allTranslations: [TranslationFull]) -> [Translation] {
        let selected = simplePersistence.valueForKey(.selectedTranslations)
        let translationsById = allTranslations.map { $0.translation }.flatGroup { $0.id }
        return selected.compactMap { translationsById[$0] }
    }

    private func arabicPromise(ayahs: [AyahNumber]) -> Promise<[AyahText]> {
        return Promise.value(ayahs).map(retrieveArabicText(ayahs:))
    }

    private func retrieveArabicText(ayahs: [AyahNumber]) throws -> [AyahText] {
        return try ayahs.map(arabicPersistence.getQuranAyahTextForNumberAsAyahText)
    }

    private func retrieveAllTranslations(ayahs: [AyahNumber], translations: [Translation]) -> [(Translation, [AyahText])] {
        return translations.map { retrieveTranslationText(ayahs: ayahs, translation: $0) }
    }

    private func retrieveTranslationText(ayahs: [AyahNumber], translation: Translation) -> (Translation, [AyahText]) {
        let fileURL = Files.translationsURL.appendingPathComponent(translation.fileName)
        let persistence = translationsPersistenceBuilder.build(with: fileURL.absoluteString)
        var ayahTexts: [AyahText] = []
        for ayah in ayahs {
            let text: String
            do {
                if let ayahText = try persistence.getTranslationAyahTextForNumber(ayah) {
                    text = ayahText
                } else {
                    text = l("noAvailableTranslationText")
                }
            } catch {
                Crash.recordError(error, reason: "Issue getting ayah \(ayah), translation: \(translation.id)", fatalErrorOnDebug: false)
                text = l("errorInTranslationText")
            }
            ayahTexts.append(AyahText(ayah: ayah, text: text))
        }
        return (translation, ayahTexts)
    }
}

private extension TranslationAyahTextPersistence {
    func getTranslationAyahTextForNumberAsAyahText(_ number: AyahNumber) throws -> AyahText? {
        let text = try getTranslationAyahTextForNumber(number)
        return text.map { AyahText(ayah: number, text: $0) }
    }
}

private extension QuranAyahTextPersistence {
    func getQuranAyahTextForNumberAsAyahText(_ number: AyahNumber) throws -> AyahText {
        return AyahText(ayah: number, text: try getQuranAyahTextForNumber(number))
    }
}

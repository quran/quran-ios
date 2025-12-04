//
//  ShareableVerseTextRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/4/17.
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
import Localization
import QuranKit
import QuranText
import TranslationService
import VerseTextPersistence

public struct ShareableVerseTextRetriever {
    // MARK: Lifecycle

    public init(databasesURL: URL, quranFileURL: URL) {
        textService = QuranTextDataService(databasesURL: databasesURL, quranFileURL: quranFileURL)
        shareableVersePersistence = GRDBQuranVerseTextPersistence(mode: .share, fileURL: quranFileURL)
        localTranslationsRetriever = LocalTranslationsRetriever(databasesURL: databasesURL)
    }

    init(
        textService: QuranTextDataService,
        shareableVersePersistence: VerseTextPersistence,
        localTranslationsRetriever: LocalTranslationsRetriever
    ) {
        self.textService = textService
        self.shareableVersePersistence = shareableVersePersistence
        self.localTranslationsRetriever = localTranslationsRetriever
    }

    // MARK: Public

    public func textForVerses(_ verses: [AyahNumber]) async throws -> [String] {
        async let arabicText = arabicScript(for: verses)
        async let translationText = translations(for: verses)

        let result = try await [arabicText, translationText].flatMap { $0 }
        return result + ["", versesSummary(verses)]
    }

    // MARK: Private

    private let preferences = QuranContentStatePreferences.shared
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    private let textService: QuranTextDataService
    private let shareableVersePersistence: VerseTextPersistence
    private let localTranslationsRetriever: LocalTranslationsRetriever

    private func versesSummary(_ verses: [AyahNumber]) -> String {
        if verses.count == 1 {
            return verses[0].localizedName
        }
        return "\(verses[0].localizedName) - \(verses.last!.localizedName)"
    }

    private func arabicText(for verse: AyahNumber) async throws -> String {
        let verseNumber = NumberFormatter.arabicNumberFormatter.format(verse.ayah)

        // Avoid the arabic text to be displayed in the wrong direction in LTR languages
        let rightToLeftMark = "\u{202B}"
        let endMark = "\u{202C}"

        let arabicVerse = try await shareableVersePersistence.textForVerse(verse) + "﴿ \(verseNumber) ﴾"

        return "\(rightToLeftMark)\(arabicVerse)\(endMark)"
    }

    private func arabicScript(for verses: [AyahNumber]) async throws -> [String] {
        // TODO: improve performance by parallize the loading
        let arabicAyahsText = try await verses.asyncMap { try await arabicText(for: $0) }
            .joined(separator: " ")
        return [arabicAyahsText]
    }

    private func translations(for verses: [AyahNumber]) async throws -> [String] {
        guard preferences.quranMode == .translation else {
            return []
        }

        let translations = try await selectedTranslations()
        let verseTexts = try await textService.textForVerses(verses, translations: translations)
        let orderedVerseTexts = verses.compactMap { verseTexts[$0] }
        return versesTranslationsText(translations: translations, verseTexts: orderedVerseTexts)
    }

    private func versesTranslationsText(translations: [Translation], verseTexts: [VerseText]) -> [String] {
        var components = [""]

        for (index, translation) in translations.enumerated() {
            // translator
            components.append("• \(translation.translationName):")

            // translation text for all verses
            components.append(contentsOf: verseTexts.map { stringFromTranslationText($0.translations[index]) })

            // separate multiple translations
            components.append("")
        }

        return components.dropLast()
    }

    private func selectedTranslations() async throws -> [Translation] {
        let localTranslations = try await localTranslationsRetriever.getLocalTranslations()
        return selectedTranslationsPreferences.selectedTranslations(from: localTranslations)
    }

    private func stringFromTranslationText(_ text: TranslationText) -> String {
        switch text {
        case .reference(let verse):
            return lFormat("translation.text.see-referenced-verse", verse.ayah)
        case .string(let string):
            return string.text
        }
    }
}

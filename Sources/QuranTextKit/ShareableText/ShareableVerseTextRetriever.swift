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
import PromiseKit
import QuranKit
import TranslationService

public struct ShareableVerseTextRetriever {
    private let preferences = QuranContentStatePreferences.shared
    private let textService: QuranTextDataService
    private let shareableVersePersistence: VerseTextPersistence

    public init(databasesURL: URL, quranFileURL: URL) {
        textService = QuranTextDataService(databasesURL: databasesURL, quranFileURL: quranFileURL)
        shareableVersePersistence = GRDBQuranVerseTextPersistence(mode: .share, fileURL: quranFileURL)
    }

    init(textService: QuranTextDataService,
         shareableVersePersistence: VerseTextPersistence)
    {
        self.textService = textService
        self.shareableVersePersistence = shareableVersePersistence
    }

    public func textForVerses(_ verses: [AyahNumber]) -> Promise<[String]> {
        DispatchQueue.global().asyncPromise {
            async let arabicText = arabicScript(for: verses)
            async let translationText = translations(for: verses)

            let result = try await [arabicText, translationText].flatMap { $0 }
            return result + ["", versesSummary(verses)]
        }
    }

    private func versesSummary(_ verses: [AyahNumber]) -> String {
        if verses.count == 1 {
            return verses[0].localizedName
        }
        return "\(verses[0].localizedName) - \(verses.last!.localizedName)"
    }

    private func arabicText(for verse: AyahNumber) async throws -> String {
        let verseNumber = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
        return try await shareableVersePersistence.textForVerse(verse) + "﴿ \(verseNumber) ﴾"
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

        let translatedVerses = try await textService.textForVerses(verses)
        return versesTranslationsText(translatedVerses: translatedVerses)
    }

    private func versesTranslationsText(translatedVerses: TranslatedVerses) -> [String] {
        var components = [""]

        // group by translation
        for (i, translation) in translatedVerses.translations.enumerated() {
            // translator
            components.append("• \(translation.translationName):")

            // translation text for all verses
            components.append(contentsOf: translatedVerses.verses.map { stringFromTranslationText($0.translations[i]) })

            // separate multiple translations
            components.append("")
        }

        return components.dropLast()
    }

    private func stringFromTranslationText(_ text: TranslationText) -> String {
        switch text {
        case .reference(let verse):
            return lFormat("referenceVerseTranslationText", verse.ayah)
        case .string(let string):
            return string.text
        }
    }
}

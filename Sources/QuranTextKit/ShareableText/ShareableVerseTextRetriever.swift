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
import PromiseKit
import QuranKit
import TranslationService

public class ShareableVerseTextRetriever {
    private let preferences: QuranContentStatePreferences
    private let textService: QuranTextDataService
    private let shareableVersePersistence: VerseTextPersistence

    public init(databasesPath: String) {
        preferences = DefaultsQuranContentStatePreferences(userDefaults: .standard)
        textService = QuranTextDataService(databasesPath: databasesPath)
        shareableVersePersistence = SQLiteQuranVerseTextPersistence(quran: Quran.madani, mode: .share)
    }

    init(preferences: QuranContentStatePreferences,
         textService: QuranTextDataService,
         shareableVersePersistence: VerseTextPersistence)
    {
        self.preferences = preferences
        self.textService = textService
        self.shareableVersePersistence = shareableVersePersistence
    }

    public func textForVerses(_ verses: [AyahNumber], page: Page) -> Promise<[String]> {
        when(fulfilled: arabicScript(for: verses), translations(for: verses, page: page))
            .map { [$0, $1].flatMap { $0 } }
            .map { $0 + ["", self.versesSummary(verses)] }
    }

    private func versesSummary(_ verses: [AyahNumber]) -> String {
        if verses.count == 1 {
            return verses[0].localizedName
        }
        return "\(verses[0].localizedName) - \(verses.last!.localizedName)"
    }

    private func arabicText(for verse: AyahNumber) throws -> String {
        let verseNumber = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
        return try shareableVersePersistence.textForVerse(verse) + "﴿ \(verseNumber) ﴾"
    }

    private func arabicScript(for verses: [AyahNumber]) -> Promise<[String]> {
        DispatchQueue.global()
            .async(.promise) {
                // TODO: improve performance by loading
                try verses.map { try self.arabicText(for: $0) }
                    .joined(separator: " ")
            }
            .map { [$0] }
    }

    private func translations(for verses: [AyahNumber], page: Page) -> Promise<[String]> {
        guard preferences.quranMode == .translation else {
            return .value([])
        }

        return textService.textForPage(page).map { page -> [String] in
            let versesText = page.verses.filter { verses.contains($0.verse) }
            return self.versesTranslationsText(versesText)
        }
    }

    private func versesTranslationsText(_ verses: [VerseText]) -> [String] {
        var components = [""]

        // group by translation
        for (i, translation) in verses[0].translations.enumerated() {
            // translator
            components.append("• \(translation.translation.translationName):")

            // translation text for all verses
            components.append(contentsOf: verses.map { $0.translations[i].text })

            // separate multiple translations
            components.append("")
        }

        return components.dropLast()
    }
}

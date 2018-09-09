//
//  Analytics.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/8/17.
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

import Crashlytics
import QueuePlayer

struct Analytics {
    static let shared = Analytics()

    private init() { }

    func logSystemLanguage() {
        let current = Locale.current
        let english = Locale(identifier: "en")
        let systemLanguage = current.languageCode.flatMap { english.localizedString(forLanguageCode: $0) } ?? "[\(current.identifier)]"
        CLog("System Language:", systemLanguage)
        Answers.logCustomEvent(withName: "System Language", customAttributes: ["language" : systemLanguage])

    }

    func showing(screen: Screen) {
        CLog("Showing Page:", screen.rawValue)
        Answers.logContentView(withName: screen.rawValue,
                               contentType: "Scrren Type",
                               contentId: nil,
                               customAttributes: nil)
    }

    func showing(quranPage page: Int, isTranslation: Bool, numberOfSelectedTranslations: Int, fontSize: FontSize, theme: Theme) {
        CLog("Showing Quran Page:", page,
             "isTranslation:", isTranslation,
             "numberOfSelectedTranslations:", numberOfSelectedTranslations,
             "fontSize:", fontSize,
             "theme:", theme
        )

        var attributes: [String: Any] = [
            "page": "\(page)",
            "Viewing Mode": isTranslation ? "Translation" : "Arabic",
            "theme": theme.rawValue.description
        ]
        if isTranslation {
            attributes["Selected Translations"] = numberOfSelectedTranslations
            attributes["Font Size"] = fontSize.rawValue.description
        }
        Answers.logCustomEvent(withName: "ShowingQuranPage", customAttributes: attributes)
    }

    func downloading(translation: Translation) {
        CLog("Downloading translation:", translation.id)
        Answers.logCustomEvent(withName: "Translations Downloading", customAttributes: [
            "id" : "\(translation.id)", "displayName": translation.displayName, "language": translation.languageCode])
    }

    func deleting(translation: Translation) {
        CLog("Deleting translation:", translation.id)
        Answers.logCustomEvent(withName: "Translations Deletion", customAttributes: [
            "id" : "\(translation.id)", "displayName": translation.displayName, "language": translation.languageCode])
    }

    func bookmark(ayah: AyahNumber) {
        let ayahText = "\(ayah.sura):\(ayah.ayah)"
        CLog("Bookmarking Ayah:", ayahText)
        Answers.logCustomEvent(withName: "Bookmark Ayah", customAttributes: ["ayah": ayahText])
    }

    func bookmark(quranPage page: Int) {
        CLog("Bookmarking Page:", page)
        Answers.logCustomEvent(withName: "Bookmark Page", customAttributes: ["page": "\(page)"])
    }

    func unbookmark(ayah: AyahNumber) {
        let ayahText = "\(ayah.sura):\(ayah.ayah)"
        CLog("Unbookmarking Ayah:", ayahText)
        Answers.logCustomEvent(withName: "Unbookmark Ayah", customAttributes: ["ayah": ayahText])
    }

    func unbookmark(quranPage page: Int) {
        CLog("Unbookmarking Page:", page)
        Answers.logCustomEvent(withName: "Unbookmark Page", customAttributes: ["page": "\(page)"])
    }

    func playing(startAyah start: AyahNumber, to: AyahNumber, qari: Qari, verseRuns: Runs, listRuns: Runs) {
        CLog(
            "Playing Audio from:", start.shortDescription,
            "to:", to.shortDescription,
            "qri:", qari.id,
            "verseRuns:", verseRuns.shortDescription,
            "listRuns:", listRuns.shortDescription
        )
        Answers.logCustomEvent(withName: "Audio Playing", customAttributes: [
            "from": start.shortDescription,
            "to": to.shortDescription,
            "qari.id": qari.id,
            "qari.name": qari.name,
            "verseRuns": verseRuns.shortDescription,
            "listRuns": listRuns.shortDescription
        ])
    }

    func downloadingJuz(startAyah ayah: AyahNumber, qari: Qari) {
        let ayahText = "\(ayah.sura):\(ayah.ayah)"
        CLog("Downloading juz' from:", ayahText, "qri:", qari.id)
        Answers.logCustomEvent(withName: "Juz Downloading", customAttributes: ["ayah": ayahText, "qari.id": qari.id, "qari.name": qari.name])
    }

    func downloadingQuran(qari: Qari) {
        CLog("Downloading entire quran qari:", qari.id)
        Answers.logCustomEvent(withName: "Quran Downloading", customAttributes: ["qari.id": qari.id, "qari.name": qari.name])
    }

    func deletingQuran(qari: Qari) {
        CLog("Deleting audio for qari:", qari.id)
        Answers.logCustomEvent(withName: "Audio Deletion", customAttributes: ["qari.id": qari.id, "qari.name": qari.name])
    }

    func searching(for term: String, source: SearchResult.Source, resultsCount: Int) {
        CLog("Searching for '\(term)'; source=(source); getting \(resultsCount) results.")
        Answers.logCustomEvent(withName: "SearchTerm", customAttributes: ["term": term, "resultsCount": resultsCount])
    }

    func openingQuran(from screen: Screen) {
        CLog("opening Quran from:", screen.rawValue)
        Answers.logCustomEvent(withName: "OpeningQuran", customAttributes: ["from": screen.rawValue])
    }

    func review(automatic: Bool) {
        CLog("Requesting user review automatic:", automatic)
        Answers.logCustomEvent(withName: "RequestReview", customAttributes: ["automatic": automatic.description])
    }

    func shareApp() {
        CLog("User sharing the app")
        Answers.logCustomEvent(withName: "ShareApp", customAttributes: nil)
    }

    func playFrom(menu: Bool) {
        let from = menu ? "Menu" : "AudioBar"
        CLog("Play Audio From:", from)
        Answers.logCustomEvent(withName: "PlayAudioFrom", customAttributes: ["from": from])
    }
}

extension AyahNumber {
    fileprivate var shortDescription: String {
        return "\(sura):\(ayah)"
    }
}

extension Runs {
    fileprivate var shortDescription: String {
        switch self {
        case .one:          return "1"
        case .two:          return "2"
        case .three:        return "3"
        case .four:         return "4"
        case .indefinite:   return "∞"
        }
    }
}

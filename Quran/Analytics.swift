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

struct Analytics {
    static let shared = Analytics()

    private init() { }

    func logSystemLanguage() {
        let current = Locale.current
        let english = Locale(identifier: "en")
        let systemLanguage = current.languageCode.flatMap { english.localizedString(forLanguageCode: $0) } ?? "[\(current.identifier)]"
        Answers.logCustomEvent(withName: "System Language", customAttributes: ["language" : systemLanguage])
    }

    func showing(screen: Screen) {
        Answers.logContentView(withName: screen.rawValue,
                               contentType: "Scrren Type",
                               contentId: nil,
                               customAttributes: nil)
    }

    func showing(quranPage page: Int) {
        Answers.logContentView(withName: "QuranPage: \(page)",
                               contentType: "QuranPage",
                               contentId: nil,
                               customAttributes: nil)
    }

    func downloading(translation: Translation) {
        Answers.logCustomEvent(withName: "Translations Downloading", customAttributes: [
            "id" : "\(translation.id)", "displayName": translation.displayName, "language": translation.languageCode])
    }

    func deleting(translation: Translation) {
        Answers.logCustomEvent(withName: "Translations Deletion", customAttributes: [
            "id" : "\(translation.id)", "displayName": translation.displayName, "language": translation.languageCode])
    }

    func bookmark(ayah: AyahNumber) {
        Answers.logCustomEvent(withName: "Bookmark Ayah", customAttributes: ["ayah": "\(ayah.sura):\(ayah.ayah)"])
    }

    func bookmark(quranPage page: Int) {
        Answers.logCustomEvent(withName: "Bookmark Page", customAttributes: ["page": "\(page)"])
    }

    func unbookmark(ayah: AyahNumber) {
        Answers.logCustomEvent(withName: "Unbookmark Ayah", customAttributes: ["ayah": "\(ayah.sura):\(ayah.ayah)"])
    }

    func unbookmark(quranPage page: Int) {
        Answers.logCustomEvent(withName: "Unbookmark Page", customAttributes: ["page": "\(page)"])
    }

    func playing(startAyah ayah: AyahNumber, qari: Qari) {
        Answers.logCustomEvent(withName: "Audio Playing", customAttributes: [
            "ayah": "\(ayah.sura):\(ayah.ayah)", "qari.id": qari.id, "qari.name": qari.name])
    }

    func downloading(startAyah ayah: AyahNumber, qari: Qari) {
        Answers.logCustomEvent(withName: "Audio Downloading", customAttributes: [
            "ayah": "\(ayah.sura):\(ayah.ayah)", "qari.id": qari.id, "qari.name": qari.name])
    }
}

//
//  UserDefaults+Keys.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/17.
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
extension PersistenceKeyBase {
    static let lastSelectedQariId = PersistenceKey<Int>(key: "LastSelectedQariId", defaultValue: 9)
    static let lastViewedPage = PersistenceKey<Int?>(key: "LastViewedPage", defaultValue: nil)
    static let showQuranTranslationView = PersistenceKey<Bool>(key: "showQuranTranslationView", defaultValue: false)
    static let selectedTranslations = PersistenceKey<[Int]>(key: "selectedTranslations", defaultValue: [])
    static let wordTranslationType = PersistenceKey<Int>(key: "wordTranslationType", defaultValue: AyahWord.TextType.translation.rawValue)
    static let appOpenedCounter = PersistenceKey<Int>(key: "appOpenedCounter", defaultValue: 0)
    static let appInstalledDate = PersistenceKey<TimeInterval>(key: "appInstalledDate", defaultValue: 0)
    static let requestReviewDate = PersistenceKey<TimeInterval?>(key: "requestReviewDate", defaultValue: nil)
    static let fontSizeRaw = PersistenceKey<Int?>(key: "fontSize", defaultValue: nil)
    static let themeRaw = PersistenceKey<Int>(key: "theme", defaultValue: Theme.light.rawValue)
}

extension SimplePersistence {
    var fontSize: FontSize {
        get {
            return  valueForKey(.fontSizeRaw).flatMap { FontSize(rawValue: $0) } ?? .medium
        }
        set {
            setValue(newValue.rawValue, forKey: PersistenceKeyBase.fontSizeRaw)
        }
    }

    var theme: Theme {
        get {
            return Theme(rawValue: valueForKey(.themeRaw)) ?? .light
        }
        set {
            setValue(newValue.rawValue, forKey: .themeRaw)
            NotificationCenter.default.post(name: .themeDidChange, object: newValue)
        }
    }
}

extension NSNotification.Name {
    static let themeDidChange = NSNotification.Name("themeDidChange")
}

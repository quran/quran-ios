//
//  Localizations.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/13/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
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

enum Language: String {
    case base = "Base"
    case arabic = "ar"
    case english = "en"
}

func l(_ key: String, table: String = "Localizable", language: Language? = nil) -> String {
    if let language = language {
        return localizedString(key, table: table, language: language)
    }
    let value = NSLocalizedString(key, tableName: table, comment: "")
    if value != key || NSLocale.preferredLanguages.first == "en" {
        return value
    }

    // Fall back to en
    return localizedString(key, table: table, language: .base)
}

private func localizedString(_ key: String, table: String = "Localizable", language: Language) -> String {
    guard
        let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
        let bundle = Bundle(path: path)
        else { return key }
    return NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
}

func lAndroid(_ key: String, language: Language? = nil) -> String {
    return l(key, table: "Android", language: language)
}

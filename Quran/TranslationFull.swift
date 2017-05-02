//
//  TranslationFull.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/1/17.
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
import BatchDownloader

struct TranslationFull: Downloadable {
    let translation: Translation
    var response: DownloadBatchResponse?

    var isDownloaded: Bool { return translation.installedVersion != nil }
    var needsUpgrade: Bool { return translation.installedVersion != translation.version }

}

extension TranslationFull: Equatable {

    static func == (lhs: TranslationFull, rhs: TranslationFull) -> Bool {
        return lhs.translation == rhs.translation
    }
}

extension TranslationFull: Comparable {
    static func < (lhs: TranslationFull, rhs: TranslationFull) -> Bool {
        // items that should be upgraded should be at the top
        let lUpgrading = lhs.state.isUpgrade()
        let rUpgrading = rhs.state.isUpgrade()
        if lUpgrading != rUpgrading {
            return lUpgrading
        }

        // items with device language should be at the top
        let lIsDeviceLanguage = Locale.current.languageCode == lhs.translation.languageCode
        let rIsDeviceLanguage = Locale.current.languageCode == rhs.translation.languageCode
        if lIsDeviceLanguage != rIsDeviceLanguage {
            return lIsDeviceLanguage
        }

        return lhs.translation.displayName < rhs.translation.displayName
    }
}

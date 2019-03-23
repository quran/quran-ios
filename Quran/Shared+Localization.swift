//
//  Shared+Localization.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/7/18.
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

extension AyahNumber {

    var localizedName: String {
        let ayahNumberString = String.localizedStringWithFormat(lAndroid("quran_ayah"), ayah)
        let suraName = Quran.nameForSura(sura)
        return "\(suraName), \(ayahNumberString)"
    }
}

extension Quran {
    static func nameForSura(_ sura: Int, withPrefix: Bool = false, language: Language? = nil) -> String {
        let suraName = l("sura_names[\(sura - 1)]", table: "Suras", language: language)
        if !withPrefix {
            return suraName
        }
        let suraFormat = lAndroid("quran_sura_title", language: language)
        return String(format: suraFormat, suraName)
    }
}

//
//  Shared+Localization.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/7/18.
//  Copyright © 2018 Quran.com. All rights reserved.
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

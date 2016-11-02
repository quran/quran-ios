//
//  JuzBasedLastAyahFinder.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/13/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct JuzBasedLastAyahFinder: LastAyahFinder {

    func findLastAyah(startAyah: AyahNumber, page: Int) -> AyahNumber {

        precondition(Quran.QuranPagesRange.contains(page), "Page '\(page)' is not a valid quran page")

        let juz = Juz.juzFromPage(page)

        guard juz.juzNumber < Quran.QuranJuzsRange.upperBound else {
            // last juz, get last ayah
            let lastSura = Quran.QuranSurasRange.upperBound
            return AyahNumber(sura: lastSura, ayah: Quran.numberOfAyahsForSura(lastSura))
        }

        let juzLastAyah = Quran.Quarters[juz.juzNumber * Quran.NumberOfQuartersPerJuz].previousAyah()
        return juzLastAyah! // swiftlint:disable:this force_unwrapping
    }
}

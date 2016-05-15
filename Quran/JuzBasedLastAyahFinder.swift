//
//  JuzBasedLastAyahFinder.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/13/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct JuzBasedLastAyahFinder: LastAyahFinder {

    let pageFinder = PageBasedLastAyahFinder()

    func findLastAyah(startAyah startAyah: AyahNumber, page: Int) -> AyahNumber {

        let pageLastAyah = pageFinder.findLastAyah(startAyah: startAyah, page: page)
        let juz = Juz.juzFromPage(page)

        // if last juz, get last ayah
        guard juz.order != Quran.QuranJuzsRange.endIndex.predecessor() else {
            let lastSura = Quran.QuranSurasRange.endIndex.predecessor()
            return AyahNumber(sura: lastSura, ayah: Quran.numberOfAyahsForSura(lastSura))
        }

        let endJuz = Quran.Quarters[juz.order * Quran.NumberOfQuartersPerJuz]
        if pageLastAyah.sura > endJuz.sura ||
            (pageLastAyah.sura == endJuz.sura && pageLastAyah.ayah > endJuz.ayah) {
            return Quran.Quarters[(juz.order + 1) * Quran.NumberOfQuartersPerJuz]
        } else {
            return endJuz
        }
    }
}

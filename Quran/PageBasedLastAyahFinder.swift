//
//  PageBasedLastAyahFinder.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/13/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct PageBasedLastAyahFinder: LastAyahFinder {

    func findLastAyah(startAyah startAyah: AyahNumber, page: Int) -> AyahNumber {
        guard Quran.QuranPagesRange.contains(page) else {
            fatalError("Page '\(page)' is not a valid quran page")
        }
        let lastPage = Quran.QuranPagesRange.endIndex.predecessor()
        guard page < lastPage else {
            // last page, then get last ayah
            let lastSura = Quran.QuranSurasRange.endIndex.predecessor()
            return AyahNumber(sura: lastSura, ayah: Quran.SuraNumberOfAyahs[lastSura - 1])
        }

        let nextPageIndex = (page - 1) + 1
        let nextPageSura = Quran.PageSuraStart[nextPageIndex]
        let nextPageAyah = Quran.PageAyahStart[nextPageIndex]

        // if next page is a new sura
        if nextPageAyah == 1 {
            let sura = nextPageSura - 1
            return AyahNumber(sura: sura, ayah: Quran.SuraNumberOfAyahs[sura - 1])
        } else {
            return AyahNumber(sura: nextPageSura, ayah: nextPageAyah - 1)
        }
    }
}

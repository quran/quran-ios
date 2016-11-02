//
//  PageBasedLastAyahFinder.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/13/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct PageBasedLastAyahFinder: LastAyahFinder {

    func findLastAyah(startAyah: AyahNumber, page: Int) -> AyahNumber {
        precondition(Quran.QuranPagesRange.contains(page), "Page '\(page)' is not a valid quran page")

        guard page < Quran.QuranPagesRange.upperBound else {
            // last page, then get last ayah
            let lastSura = Quran.QuranSurasRange.upperBound
            return AyahNumber(sura: lastSura, ayah: Quran.numberOfAyahsForSura(lastSura))
        }

        let currentPageIndex = page - 1
        let nextPageIndex = currentPageIndex + 1
        let nextPageSura = Quran.PageSuraStart[nextPageIndex]
        let nextPageAyah = Quran.PageAyahStart[nextPageIndex]

        if nextPageAyah == 1 {
            // new sura
            let sura = nextPageSura - 1
            return AyahNumber(sura: sura, ayah: Quran.numberOfAyahsForSura(sura))
        } else {
            // same sura
            return AyahNumber(sura: nextPageSura, ayah: nextPageAyah - 1)
        }
    }
}

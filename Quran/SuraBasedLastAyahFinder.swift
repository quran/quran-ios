//
//  SuraBasedLastAyahFinder.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/13/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct SuraBasedLastAyahFinder: LastAyahFinder {

    let pageFinder = PageBasedLastAyahFinder()

    func findLastAyah(startAyah startAyah: AyahNumber, page: Int) -> AyahNumber {

        let pageLastAyah = pageFinder.findLastAyah(startAyah: startAyah, page: page)

        // different suras
        let sura = pageLastAyah.sura != startAyah.sura ? pageLastAyah.sura : startAyah.sura
        return AyahNumber(sura: sura, ayah: Quran.SuraNumberOfAyahs[sura - 1])
    }
}

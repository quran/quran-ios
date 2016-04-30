//
//  AyahNumber.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/24/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct AyahNumber: Hashable {
    let sura: Int
    let ayah: Int

    var hashValue: Int {
        return "\(sura):\(ayah)".hashValue
    }

    func getStartPage() -> Int {

        // sura start index
        var index = Truth.SuraPageStart[sura] - 1
        while index < Truth.QuranPagesRange.endIndex {
            // what's the first sura in that page?
            let ss = Truth.PageSuraStart[index]

            // if we've passed the sura, return the previous page
            // or, if we're at the same sura and passed the ayah
            if ss > sura || (ss == sura && Truth.PageAyahStart[index] > ayah) {
                break
            }

            // otherwise, look at the next page
            index += 1
        }

        return index
    }
}

func == (lhs: AyahNumber, rhs: AyahNumber) -> Bool {
    return lhs.sura == rhs.sura && lhs.ayah == lhs.ayah
}

//
//  VerseRange.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/23/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

struct VerseRange {
    let lowerBound: AyahNumber
    let upperBound: AyahNumber
}

extension VerseRange {

    func getAyahs() -> [AyahNumber] {
        var ayahs: [AyahNumber] = []
        for sura in lowerBound.sura...upperBound.sura {

            let startAyahNumber = sura == lowerBound.sura ? lowerBound.ayah : 1
            let endAyahNumber = sura == upperBound.sura ? upperBound.ayah : Quran.numberOfAyahsForSura(sura)

            for ayah in startAyahNumber...endAyahNumber {
                ayahs.append(AyahNumber(sura: sura, ayah: ayah))
            }
        }
        return ayahs
    }
}

//
//  AyahNumber.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/24/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct AyahNumber: Hashable, CustomStringConvertible {
    let sura: Int
    let ayah: Int

    var hashValue: Int {
        return "\(sura):\(ayah)".hashValue
    }

    func getStartPage() -> Int {

        // sura start index
        var index = Quran.SuraPageStart[sura - 1] - 1
        while index < Quran.PageSuraStart.count {
            // what's the first sura in that page?
            let ss = Quran.PageSuraStart[index]

            // if we've passed the sura, return the previous page
            // or, if we're at the same sura and passed the ayah
            if ss > sura || (ss == sura && Quran.PageAyahStart[index] > ayah) {
                break
            }

            // otherwise, look at the next page
            index += 1
        }

        return index
    }

    func nextAyah() -> AyahNumber? {
        if ayah < Quran.numberOfAyahsForSura(sura) {
            // same sura
            return AyahNumber(sura: sura, ayah: ayah + 1)
        } else {
            if sura < Quran.SuraPageStart.count {
                // next sura
                return AyahNumber(sura: sura + 1, ayah: 1)
            } else {
                return nil // last ayah
            }
        }
    }

    func previousAyah() -> AyahNumber? {
        if ayah > 1 {
            // same sura
            return AyahNumber(sura: sura, ayah: ayah - 1)
        } else if sura > 1 {
            // previous sura
            let newSura = sura - 1
            return AyahNumber(sura: newSura, ayah: Quran.numberOfAyahsForSura(newSura))
        } else {
            return nil
        }
    }

    var description: String {
        return "<AyahNumber sura=\(sura) ayah=\(ayah)>"
    }
}

func == (lhs: AyahNumber, rhs: AyahNumber) -> Bool {
    return lhs.sura == rhs.sura && lhs.ayah == rhs.ayah
}

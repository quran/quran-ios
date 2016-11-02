//
//  QuranUtilities.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

extension Juz {

    static func getJuzs() -> [Juz] {
        let juzs = Quran.QuranJuzsRange.map { Juz(juzNumber: $0) }
        return juzs
    }

    static func juzFromPage(_ page: Int) -> Juz {
        for (index, juzStartPage) in Quran.JuzPageStart.enumerated() {
            if page < juzStartPage {
                let previousIndex = index - 1
                let juzNumber = previousIndex + Quran.QuranJuzsRange.lowerBound
                return Juz(juzNumber: juzNumber)
            }
        }
        let juzNumber = Quran.QuranJuzsRange.upperBound
        return Juz(juzNumber: juzNumber)
    }
}

extension Sura {

    static func getSuras() -> [Sura] {

        var suras: [Sura] = []

        for i in 0..<Quran.SuraPageStart.count {
            suras.append(Sura(
                suraNumber: i + 1,
                isMAkki: Quran.SuraIsMakki[i],
                numberOfAyahs: Quran.SuraNumberOfAyahs[i],
                startPageNumber: Quran.SuraPageStart[i]))
        }
        return suras
    }
}

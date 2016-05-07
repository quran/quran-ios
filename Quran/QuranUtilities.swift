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
        let juzs = Quran.JuzPageStart.enumerate().map { Juz(order: $0 + 1, startPageNumber: $1) }
        return juzs
    }
}

extension Sura {

    static func getSuras() -> [Sura] {

        var suras: [Sura] = []

        for i in 0..<Quran.SuraPageStart.count {
            suras.append(Sura(
                order: i + 1,
                isMAkki: Quran.SuraIsMakki[i],
                numberOfAyahs: Quran.SuraNumberOfAyahs[i],
                startPageNumber: Quran.SuraPageStart[i]))
        }
        return suras
    }
}

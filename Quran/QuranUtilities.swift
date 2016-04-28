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
        let juzs = Truth.JuzPageStart.enumerate().map { Juz(order: $0 + 1, startPageNumber: $1) }
        return juzs
    }
}

extension Sura {

    static func getSuras() -> [Sura] {

        var suras: [Sura] = []

        for i in 0..<Truth.SuraPageStart.count {
            suras.append(Sura(
                order: i + 1,
                name: NSLocalizedString("sura_names[\(i)]", comment: ""),
                isMAkki: Truth.SuraIsMakki[i],
                numberOfAyahs: Truth.SuraNumberOfAyahs[i],
                startPageNumber: Truth.SuraPageStart[i]))
        }
        return suras
    }
}

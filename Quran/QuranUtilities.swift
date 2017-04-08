//
//  QuranUtilities.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation

extension Juz {

    static func getJuzs() -> [Juz] {
        let juzs = Quran.QuranJuzsRange.map { Juz(juzNumber: $0) }
        return juzs
    }

    static func juzFromPage(_ page: Int) -> Juz {
        for (index, juzStartPage) in Quran.JuzPageStart.enumerated() where page < juzStartPage {
            let previousIndex = index - 1
            let juzNumber = previousIndex + Quran.QuranJuzsRange.lowerBound
            return Juz(juzNumber: juzNumber)
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

//
//  SurasDataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/25/16.
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

import PromiseKit

struct JuzSuras {
    let juz: Juz
    let suras: [Sura]
}

protocol SurasDataRetrieverType {
    func getSuras() -> Guarantee<[JuzSuras]>
}

final class SurasDataRetriever: SurasDataRetrieverType {

    func getSuras() -> Guarantee<[JuzSuras]> {
        return DispatchQueue.global().async(.guarantee) {
            let juzs = Juz.getJuzs()
            let suras = Sura.getSuras()

            var juzsGroup: [JuzSuras] = []

            var suraIndex = 0
            for juzIndex in 0..<juzs.count {

                let juz = juzs[juzIndex]
                let nextJuzStartPage = juz == juzs.last ? Quran.QuranPagesRange.upperBound + 1 : juzs[juzIndex + 1].startPageNumber

                var currentSuras: [Sura] = []
                while suraIndex < suras.count {
                    let sura = suras[suraIndex]
                    guard sura.startPageNumber < nextJuzStartPage else {
                        break
                    }
                    currentSuras.append(sura)
                    suraIndex += 1
                }
                juzsGroup.append(JuzSuras(juz: juz, suras: currentSuras))
            }
            return juzsGroup
        }
    }
}

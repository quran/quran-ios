//
//  SurasDataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/25/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct SurasDataRetriever: DataRetriever {
    func retrieve(onCompletion onCompletion: [(Juz, [Sura])] -> Void) {

        Queue.background.async {
            let juzs = Juz.getJuzs()
            let suras = Sura.getSuras()

            var juzsGroup: [(Juz, [Sura])] = []

            var suraIndex = 0
            for juzIndex in 0..<juzs.count {

                let juz = juzs[juzIndex]
                let nextJuzStartPage = juz == juzs.last ? Quran.QuranPagesRange.endIndex + 1 : juzs[juzIndex + 1].startPageNumber

                var currentSuras: [Sura] = []
                while suraIndex < suras.count {
                    let sura = suras[suraIndex]
                    guard sura.startPageNumber < nextJuzStartPage else {
                        break
                    }
                    currentSuras.append(sura)
                    suraIndex += 1
                }
                juzsGroup.append((juz, currentSuras))
            }
            Queue.main.async {
                onCompletion(juzsGroup)
            }
        }
    }
}

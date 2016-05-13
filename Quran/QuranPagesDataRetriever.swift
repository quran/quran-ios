//
//  QuranPagesDataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/5/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct QuranPagesDataRetriever: DataRetriever {
    func retrieve(onCompletion onCompletion: [QuranPage] -> Void) {

        Queue.background.async {

            var pages: [QuranPage] = []

            let startIndex = Quran.QuranPagesRange.startIndex
            for i in 0..<Quran.QuranPagesRange.count {

                let pageNumber = i + startIndex
                let sura = Quran.PageSuraStart[i]
                let ayah = Quran.PageAyahStart[i]
                let juzNumber = Juz.juzFromPage(pageNumber).order

                let page = QuranPage(pageNumber: pageNumber, startAyah: AyahNumber(sura: sura, ayah: ayah), juzNumber: juzNumber)
                pages.append(page)
            }

            Queue.main.async {
                onCompletion(pages)
            }
        }
    }
}

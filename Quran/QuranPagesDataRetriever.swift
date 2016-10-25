//
//  QuranPagesDataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/5/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct QuranPagesDataRetriever: DataRetriever {
    func retrieve(onCompletion: @escaping ([QuranPage]) -> Void) {

        Queue.background.async {

            var pages: [QuranPage] = []

            let startIndex = Quran.QuranPagesRange.lowerBound
            for i in 0..<Quran.QuranPagesRange.count {

                let pageNumber = i + startIndex
                let ayah = Quran.startAyahForPage(pageNumber)
                let juzNumber = Juz.juzFromPage(pageNumber).order

                let page = QuranPage(pageNumber: pageNumber, startAyah: ayah, juzNumber: juzNumber)
                pages.append(page)
            }

            Queue.main.async {
                onCompletion(pages)
            }
        }
    }
}

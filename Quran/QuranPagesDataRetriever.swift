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

            for pageNumber in Quran.QuranPagesRange {

                let ayah = Quran.startAyahForPage(pageNumber)
                let juzNumber = Juz.juzFromPage(pageNumber).juzNumber

                let page = QuranPage(pageNumber: pageNumber, startAyah: ayah, juzNumber: juzNumber)
                pages.append(page)
            }

            Queue.main.async {
                onCompletion(pages)
            }
        }
    }
}

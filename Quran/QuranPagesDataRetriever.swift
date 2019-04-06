//
//  QuranPagesDataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/5/16.
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

protocol QuranPagesDataRetrieverType {
    func getPages() -> Guarantee<[QuranPage]>
}

struct QuranPagesDataRetriever: QuranPagesDataRetrieverType {

    func getPages() -> Guarantee<[QuranPage]> {
        return DispatchQueue.global().async(.guarantee) {
            var pages: [QuranPage] = []
            for pageNumber in Quran.QuranPagesRange {

                let ayah = Quran.startAyahForPage(pageNumber)
                let juzNumber = Juz.juzFromPage(pageNumber).juzNumber

                let page = QuranPage(pageNumber: pageNumber, startAyah: ayah, juzNumber: juzNumber)
                pages.append(page)
            }
            return pages
        }
    }
}

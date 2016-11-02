//
//  QuranPage.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct QuranPage: Hashable, CustomStringConvertible {

    let pageNumber: Int

    let startAyah: AyahNumber

    let juzNumber: Int

    var hashValue: Int {
        return pageNumber.hashValue
    }

    var description: String {
        return "<QuranPage page=\(pageNumber) juz=\(juzNumber) startAyah=\(startAyah)>"
    }
}

func == (lhs: QuranPage, rhs: QuranPage) -> Bool {
    return lhs.pageNumber == rhs.pageNumber
}

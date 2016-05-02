//
//  QuranPage.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct QuranPage: Hashable {
    let pageNumber: Int

    var hashValue: Int {
        return pageNumber.hashValue
    }
}

func == (lhs: QuranPage, rhs: QuranPage) -> Bool {
    return lhs.pageNumber == rhs.pageNumber
}

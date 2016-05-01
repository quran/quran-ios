//
//  Juz.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct Juz: QuranPageReference, Hashable {
    let order: Int
    let startPageNumber: Int

    var hashValue: Int {
        return order.hashValue
    }
}

func == (lhs: Juz, rhs: Juz) -> Bool {
    return lhs.order == rhs.order
}

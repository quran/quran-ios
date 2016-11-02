//
//  Juz.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct Juz: QuranPageReference, Hashable, CustomStringConvertible {
    let juzNumber: Int
    var startPageNumber: Int { return Quran.JuzPageStart[juzNumber - 1] }

    var hashValue: Int {
        return juzNumber.hashValue
    }

    var description: String {
        return "<Juz juz=\(juzNumber) startPage=\(startPageNumber)>"
    }
}

func == (lhs: Juz, rhs: Juz) -> Bool {
    return lhs.juzNumber == rhs.juzNumber
}

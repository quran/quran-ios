//
//  VerseRange.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/23/17.
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

import Foundation

struct VerseRange {
    let lowerBound: AyahNumber
    let upperBound: AyahNumber
}

extension VerseRange {

    func getAyahs() -> [AyahNumber] {
        var ayahs: [AyahNumber] = []
        for sura in lowerBound.sura...upperBound.sura {

            let startAyahNumber = sura == lowerBound.sura ? lowerBound.ayah : 1
            let endAyahNumber = sura == upperBound.sura ? upperBound.ayah : Quran.numberOfAyahsForSura(sura)

            for ayah in startAyahNumber...endAyahNumber {
                ayahs.append(AyahNumber(sura: sura, ayah: ayah))
            }
        }
        return ayahs
    }
}

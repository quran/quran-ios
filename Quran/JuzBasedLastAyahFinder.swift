//
//  JuzBasedLastAyahFinder.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/13/16.
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

struct JuzBasedLastAyahFinder: LastAyahFinder {

    func findLastAyah(startAyah: AyahNumber, page: Int) -> AyahNumber {

        precondition(Quran.QuranPagesRange.contains(page), "Page '\(page)' is not a valid quran page")

        let juz = Juz.juzFromPage(page)

        guard juz.juzNumber < Quran.QuranJuzsRange.upperBound else {
            // last juz, get last ayah
            let lastSura = Quran.QuranSurasRange.upperBound
            return AyahNumber(sura: lastSura, ayah: Quran.numberOfAyahsForSura(lastSura))
        }

        let juzLastAyah = Quran.Quarters[juz.juzNumber * Quran.NumberOfQuartersPerJuz].previousAyah()
        return juzLastAyah! // swiftlint:disable:this force_unwrapping
    }
}

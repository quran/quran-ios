//
//  Page.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
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

public struct Page: QuranValueGroup {
    public var pageNumber: Int { storage.value }
    let storage: QuranValueStorage<Self>

    public var quran: Quran {
        storage.quran
    }

    public init?(quran: Quran, pageNumber: Int) {
        if !quran.pagesRange.contains(pageNumber) {
            return nil
        }
        storage = QuranValueStorage(quran: quran, value: pageNumber, keyPath: \.pages)
    }

    init(_ storage: QuranValueStorage<Self>) {
        self.storage = storage
    }

    public var firstVerse: AyahNumber {
        AyahNumber(sura: startSura, ayah: quran.raw.startAyahOfPage[pageNumber - 1])!
    }

    public var startSura: Sura {
        Sura(quran: quran, suraNumber: quran.raw.startSuraOfPage[pageNumber - 1])!
    }

    public var startJuz: Juz {
        for (juz, nextJuz) in zip(quran.juzs, quran.juzs.dropFirst()) {
            if self < nextJuz.page {
                return juz
            }
        }
        return quran.juzs.last!
    }

    public var quarter: Quarter? {
        quran.quarters.first { $0.page == self }
    }
}

//
//  Sura.swift
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

public struct Sura: QuranValueGroup {
    public var suraNumber: Int { storage.value }
    let storage: QuranValueStorage<Self>

    public var quran: Quran {
        storage.quran
    }

    public init?(quran: Quran, suraNumber: Int) {
        if !quran.surasRange.contains(suraNumber) {
            return nil
        }
        storage = QuranValueStorage(quran: quran, value: suraNumber, keyPath: \.suras)
    }

    init(_ storage: QuranValueStorage<Self>) {
        self.storage = storage
    }

    public var startsWithBesmAllah: Bool {
        // Al-fatiha & At-tawba
        self != quran.suras.first && suraNumber != 9
    }

    public var isMakki: Bool {
        quran.raw.isMakkiSura[suraNumber - 1]
    }

    public var page: Page {
        Page(quran: quran, pageNumber: quran.raw.startPageOfSura[suraNumber - 1])!
    }

    var numberOfVerses: Int {
        quran.raw.numberOfAyahsInSura[suraNumber - 1]
    }

    public var firstVerse: AyahNumber {
        AyahNumber(sura: self, ayah: 1)!
    }

    public var lastVerse: AyahNumber {
        AyahNumber(sura: self, ayah: numberOfVerses)!
    }
}

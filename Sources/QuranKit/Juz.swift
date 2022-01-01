//
//  Juz.swift
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

public struct Juz: QuranValueGroup {
    public var juzNumber: Int { storage.value }
    let storage: QuranValueStorage<Self>

    public var quran: Quran {
        storage.quran
    }

    init(quran: Quran, juzNumber: Int) {
        storage = QuranValueStorage(quran: quran, value: juzNumber, keyPath: \.juzs)
    }

    init(_ storage: QuranValueStorage<Self>) {
        self.storage = storage
    }

    public var firstVerse: AyahNumber {
        quarter.firstVerse
    }

    public var page: Page {
        firstVerse.page
    }

    public var hizb: Hizb {
        let hizbNumber = (juzNumber - 1) * (quran.hizbs.count / quran.juzs.count) + 1
        return quran.hizbs[hizbNumber - 1]
    }

    public var quarter: Quarter {
        hizb.quarter
    }
}

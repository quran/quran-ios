//
//  Quarter.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/25/16.
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

public struct Quarter: QuranValueGroup {
    // MARK: Lifecycle

    init(quran: Quran, quarterNumber: Int) {
        storage = QuranValueStorage(quran: quran, value: quarterNumber, keyPath: \.quarters)
    }

    init(_ storage: QuranValueStorage<Self>) {
        self.storage = storage
    }

    // MARK: Public

    public var quarterNumber: Int { storage.value }
    public var quran: Quran {
        storage.quran
    }

    public var firstVerse: AyahNumber {
        let verse = quran.raw.quarters[quarterNumber - 1]
        return AyahNumber(quran: quran, sura: verse.sura, ayah: verse.ayah)!
    }

    public var page: Page {
        firstVerse.page
    }

    public var hizb: Hizb {
        let hizbNumber = (quarterNumber - 1) / (quran.quarters.count / quran.hizbs.count) + 1
        return quran.hizbs[hizbNumber - 1]
    }

    public var juz: Juz {
        let juzNumber = (quarterNumber - 1) / (quran.quarters.count / quran.juzs.count) + 1
        return quran.juzs[juzNumber - 1]
    }

    // MARK: Internal

    let storage: QuranValueStorage<Self>
}

//
//  AyahNumber.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/24/16.
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

public struct AyahNumber: Navigatable {
    public var quran: Quran { sura.quran }
    public let sura: Sura
    public let ayah: Int

    public init?(quran: Quran, sura: Int, ayah: Int) {
        guard let sura = Sura(quran: quran, suraNumber: sura) else {
            return nil
        }
        self.init(sura: sura, ayah: ayah)
    }

    public init?(sura: Sura, ayah: Int) {
        if !(1 ... sura.numberOfVerses).contains(ayah) {
            return nil
        }
        self.sura = sura
        self.ayah = ayah
    }

    public var description: String {
        "<AyahNumber sura=\(sura.suraNumber) ayah=\(ayah)>"
    }

    public static func < (lhs: AyahNumber, rhs: AyahNumber) -> Bool {
        if lhs.sura == rhs.sura {
            return lhs.ayah < rhs.ayah
        }
        return lhs.sura < rhs.sura
    }

    public var previous: AyahNumber? {
        if self != sura.firstVerse {
            // same sura
            return AyahNumber(sura: sura, ayah: ayah - 1)
        }
        // previous sura, last verse
        return sura.previous?.lastVerse
    }

    public var next: AyahNumber? {
        if self != sura.lastVerse {
            // same sura
            return AyahNumber(sura: sura, ayah: ayah + 1)
        }
        // next sura, first verse
        return sura.next?.firstVerse
    }

    public var page: Page {
        quran.pages.binarySearchFirst { self >= $0.firstVerse }
    }
}

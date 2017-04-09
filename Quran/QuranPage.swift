//
//  QuranPage.swift
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

struct QuranPage: Hashable, CustomStringConvertible {

    let pageNumber: Int

    let startAyah: AyahNumber

    let juzNumber: Int

    var hashValue: Int {
        return pageNumber.hashValue
    }

    var description: String {
        return "<QuranPage page=\(pageNumber) juz=\(juzNumber) startAyah=\(startAyah)>"
    }
}

func == (lhs: QuranPage, rhs: QuranPage) -> Bool {
    return lhs.pageNumber == rhs.pageNumber
}

//
//  Int+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/23/17.
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

extension Int {
    // Better in performance more than 50% faster than String(format: "%03d", sura)
    public func as3DigitString() -> String {
        let v3 = self / 100
        let m2 = self - v3 * 100

        let v2 = m2 / 10
        let m1 = m2 - v2 * 10

        return v3.description + v2.description + m1.description
    }
}

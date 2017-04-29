//
//  AyahInfo.swift
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

import CoreGraphics

struct AyahInfo {
    let page: Int
    let line: Int
    let ayah: AyahNumber
    let position: Int
    let minX: Int
    let maxX: Int
    let minY: Int
    let maxY: Int

    var rect: CGRect {
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    func engulf(_ other: AyahInfo) -> AyahInfo {
        return AyahInfo(page: page,
                        line: line,
                        ayah: ayah,
                        position: position,
                        minX: min(self.minX, other.minX),
                        maxX: max(self.maxX, other.maxX),
                        minY: min(self.minY, other.minY),
                        maxY: max(self.maxY, other.maxY))
    }
}

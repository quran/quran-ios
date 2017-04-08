//
//  CGRect+Extension.swift
//  Quran
//
//  Created by Ahmed El-Helw on 5/18/16.
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

extension CGRect {

    struct Scale {
        let scale: CGFloat
        let xOffset: CGFloat
        let yOffset: CGFloat

        static let zero = Scale(scale: 0, xOffset: 0, yOffset: 0)
    }

    func applyScale(_ scale: Scale) -> CGRect {
        return CGRect(x: minX * scale.scale + scale.xOffset,
                      y: minY * scale.scale + scale.yOffset,
                      width: width * scale.scale,
                      height: height * scale.scale)
    }
}

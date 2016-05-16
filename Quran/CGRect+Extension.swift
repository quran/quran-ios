//
//  CGRect+Extension.swift
//  Quran
//
//  Created by Ahmed El-Helw on 5/18/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import CoreGraphics

extension CGRect {

    func applyScale(scale: CGFloat, xOffset: CGFloat, yOffset: CGFloat) -> CGRect {
        return CGRect(x: minX * scale + xOffset,
                      y: minY * scale + yOffset,
                      width: width * scale,
                      height: height * scale)
    }
}

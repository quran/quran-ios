//
//  CGRect+Extension.swift
//  Quran
//
//  Created by Ahmed El-Helw on 5/18/16.
//  Copyright © 2016 Quran.com. All rights reserved.
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

//
//  AyahNumberLocation+Layout.swift
//

import CoreGraphics
import QuranGeometry

extension AyahNumberLocation {
    func scaledRectangle(imageSize: CGSize, scale: WordFrameScale) -> CGRect {
        let length = 0.06 * imageSize.width
        return CGRect(
            x: center.x - length / 2,
            y: center.y - length / 2,
            width: length,
            height: length
        ).scaled(by: scale)
    }
}

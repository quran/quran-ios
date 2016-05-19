//
//  HighlightingView.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/24/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

// This class is expected to be implemented using CoreAnimation with CAShapeLayers.
// It's also expected to reuse layers instead of dropping & creating new ones.
class HighlightingView: UIView {

    @IBInspectable var highlightColor: UIColor = UIColor(red: 0.275, green: 0.58, blue: 0.651, alpha: 0.25)

    var highlightedAyat: Set<AyahNumber> = Set<AyahNumber>() {
        didSet {
            setNeedsDisplay()
        }
    }

    var ayahInfoData: [AyahNumber: [AyahInfo]]? {
        didSet {
            setNeedsDisplay()
        }
    }

    private var imageScale: CGFloat = 0.0
    private var xOffset: CGFloat = 0.0
    private var yOffset: CGFloat = 0.0

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        guard highlightedAyat.count > 0 else { return }

        let context = UIGraphicsGetCurrentContext()
        for ayah in highlightedAyat {
            guard let ayahInfo = ayahInfoData?[ayah] else { continue }

            for piece in ayahInfo {
                CGContextSetFillColorWithColor(context, highlightColor.CGColor)
                CGContextFillRect(context, piece.rect.applyScale(imageScale, xOffset: xOffset, yOffset: yOffset))
            }
        }
    }

    func setScaleInfo(scale: CGFloat, xOffset: CGFloat, yOffset: CGFloat) {
        self.imageScale = scale
        self.xOffset = xOffset
        self.yOffset = yOffset
        setNeedsDisplay()
    }

    func reset() {
        highlightedAyat = Set<AyahNumber>()
        ayahInfoData = nil
        imageScale = 0.0
        xOffset = 0.0
        yOffset = 0.0
    }
}

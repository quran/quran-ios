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

    @IBInspectable var highlightColor: UIColor = UIColor.appIdentity().colorWithAlphaComponent(0.25)

    var highlightedAyat: Set<AyahNumber> = Set<AyahNumber>() {
        didSet {
            updateRectangleBounds()
        }
    }

    var ayahInfoData: [AyahNumber: [AyahInfo]]? {
        didSet {
            updateRectangleBounds()
        }
    }

    private var imageScale: CGFloat = 0.0
    private var xOffset: CGFloat = 0.0
    private var yOffset: CGFloat = 0.0

    var highlightingRectangles: [CGRect] = []

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        guard highlightedAyat.count > 0 else { return }

        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, highlightColor.CGColor)
        for rect in highlightingRectangles {
            CGContextFillRect(context, rect)
        }
    }

    func setScaleInfo(scale: CGFloat, xOffset: CGFloat, yOffset: CGFloat) {
        self.imageScale = scale
        self.xOffset = xOffset
        self.yOffset = yOffset

        updateRectangleBounds()
    }

    func reset() {
        highlightedAyat = Set<AyahNumber>()
        ayahInfoData = nil
        imageScale = 0.0
        xOffset = 0.0
        yOffset = 0.0
    }

    private func updateRectangleBounds() {

        highlightingRectangles.removeAll(keepCapacity: true)
        for ayah in highlightedAyat {
            guard let ayahInfo = ayahInfoData?[ayah] else { continue }

            for piece in ayahInfo {
                let rectangle = piece.rect.applyScale(imageScale, xOffset: xOffset, yOffset: yOffset)
                highlightingRectangles.append(rectangle)
            }
        }

        setNeedsDisplay()
    }
}

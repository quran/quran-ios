//
//  CircleView.swift
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

import UIKit

open class CircleView: UIView {

    @IBInspectable open var progress: CGFloat = 0.8 {
        didSet {
            updateLayers()
        }
    }

    @IBInspectable open var emptyColor: UIColor = UIColor.red {
        didSet {
            updateLayers()
        }
    }

    @IBInspectable open var fillColor: UIColor = UIColor.green {
        didSet {
            updateLayers()
        }
    }

    private let emptyCircle = CAShapeLayer()
    private let fillCircle = CAShapeLayer()

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        layer.addSublayer(emptyCircle)
        layer.addSublayer(fillCircle)
        fillCircle.fillColor = nil
        fillCircle.transform = CATransform3DMakeRotation(-.pi / 2, 0, 0, 1)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        updateLayers()
    }

    private func updateLayers() {
        emptyCircle.frame = bounds
        fillCircle.frame = bounds

        // emtpy circle
        //        var circleBounds = bounds
        emptyCircle.path = UIBezierPath(ovalIn: bounds).cgPath
        emptyCircle.fillColor = emptyColor.cgColor

        // fill circle
        fillCircle.path = UIBezierPath(ovalIn: bounds.insetBy(dx: bounds.width / 4, dy: bounds.height / 4)).cgPath
        fillCircle.strokeColor = fillColor.cgColor
        fillCircle.lineWidth = bounds.width / 2

        CALayer.withoutAnimation {
            fillCircle.strokeEnd = progress
        }
    }
}

//
//  CircleView.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class CircleView: UIView {

    @IBInspectable var progress: CGFloat = 0.8 {
        didSet {
            updateLayers()
        }
    }

    @IBInspectable var emptyColor: UIColor = UIColor.redColor() {
        didSet {
            updateLayers()
        }
    }

    @IBInspectable var fillColor: UIColor = UIColor.greenColor() {
        didSet {
            updateLayers()
        }
    }

    private let emptyCircle = CAShapeLayer()
    private let fillCircle = CAShapeLayer()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    /**
     Sets up the view.
     */
    func setUp() {
        layer.addSublayer(emptyCircle)
        layer.addSublayer(fillCircle)
        fillCircle.fillColor = nil
        fillCircle.transform = CATransform3DMakeRotation(CGFloat(-M_PI_2), 0, 0, 1)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayers()
    }

    private func updateLayers() {
        emptyCircle.frame = bounds
        fillCircle.frame = bounds

        // emtpy circle
        //        var circleBounds = bounds
        emptyCircle.path = UIBezierPath(ovalInRect: bounds).CGPath
        emptyCircle.fillColor = emptyColor.CGColor

        // fill circle
        fillCircle.path = UIBezierPath(ovalInRect: bounds.insetBy(dx: bounds.width / 4, dy: bounds.height / 4)).CGPath
        fillCircle.strokeColor = fillColor.CGColor
        fillCircle.lineWidth = bounds.width / 2

        CALayer.withoutAnimation {
            fillCircle.strokeEnd = progress
        }
    }
}

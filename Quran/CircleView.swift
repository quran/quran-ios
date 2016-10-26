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

    @IBInspectable var emptyColor: UIColor = UIColor.red {
        didSet {
            updateLayers()
        }
    }

    @IBInspectable var fillColor: UIColor = UIColor.green {
        didSet {
            updateLayers()
        }
    }

    fileprivate let emptyCircle = CAShapeLayer()
    fileprivate let fillCircle = CAShapeLayer()

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

    fileprivate func updateLayers() {
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

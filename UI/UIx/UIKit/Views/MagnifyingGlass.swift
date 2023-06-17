//
//  MagnifyingGlass.swift
//  UIKitExtension
//
//  Created by Afifi, Mohamed on 3/15/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import UIKit
import ViewConstrainer

public class MagnifyingGlass: UIView {
    // MARK: Lifecycle

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init() {
        magnifyingArea = MagnifyingAreaView()
        super.init(frame: .zero)

        // drop shadow
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.shadowColor = UIColor.lightGray.cgColor

        // magnify
        magnifyingArea.layer.borderColor = UIColor.lightGray.cgColor
        magnifyingArea.layer.borderWidth = 0.5
        magnifyingArea.layer.masksToBounds = true
        addAutoLayoutSubview(magnifyingArea)
        magnifyingArea.vc.edges()

        // gradient inner shadow
        let gradient = GradientView(type: .radial)
        gradient.colors = [UIColor.lightGray.withAlphaComponent(0),
                           UIColor.lightGray.withAlphaComponent(0.2)]
        addAutoLayoutSubview(gradient)
        gradient.vc.edges()
    }

    // MARK: Public

    public var touchPoint: CGPoint {
        get { magnifyingArea.touchPoint }
        set { magnifyingArea.touchPoint = newValue }
    }

    public var viewToMagnify: UIView? {
        get { magnifyingArea.viewToMagnify }
        set { magnifyingArea.viewToMagnify = newValue }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        magnifyingArea.layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    // MARK: Private

    private let magnifyingArea: MagnifyingAreaView
}

private class MagnifyingAreaView: UIView {
    var viewToMagnify: UIView?

    var scale = CGPoint(x: 1.5, y: 1.5)

    var touchPoint: CGPoint = .zero {
        didSet { setNeedsDisplay() }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.translateBy(x: frame.size.width / 2, y: frame.size.height / 2)
        context.scaleBy(x: scale.x, y: scale.y) // 1.5 is the zoom scale
        context.translateBy(x: -1 * touchPoint.x, y: -1 * touchPoint.y)
        viewToMagnify?.layer.render(in: context)
    }
}

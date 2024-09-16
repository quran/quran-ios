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
    private var scale: CGFloat = 1.5

    private let imageView = UIImageView()
    private var snapshotImage: UIImage? {
        didSet {
            imageView.image = snapshotImage
            if imageView.superview == nil {
                imageView.contentMode = .center
                imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
                addAutoLayoutSubview(imageView)
                imageView.vc.edges()
            }
        }
    }

    var viewToMagnify: UIView?

    var touchPoint: CGPoint = .zero {
        didSet {
            refreshSnapshot() // Update the snapshot when the touch point changes
        }
    }

    private func refreshSnapshot() {
        guard let viewToMagnify else {
            snapshotImage = nil
            return
        }

        // Define the area to capture around the touch point
        let snapshotSize = CGSize(width: bounds.width / scale, height: bounds.height / scale)
        let snapshotOrigin = CGPoint(
            x: touchPoint.x - snapshotSize.width / 2,
            y: touchPoint.y - snapshotSize.height / 2
        )
        let snapshotRect = CGRect(origin: snapshotOrigin, size: snapshotSize)

        // Capture the snapshot of the target area
        snapshotImage = viewToMagnify.snapshot(of: snapshotRect)
    }
}

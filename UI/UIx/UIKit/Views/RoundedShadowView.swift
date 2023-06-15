//
//  RoundedShadowView.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-02-26.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import UIKit

public class RoundedShadowView: UIView {
    public var fillColor: UIColor? = .red {
        didSet {
            updateLayerUI()
        }
    }

    public var cornerRadius: CGFloat = 100.0 {
        didSet {
            layoutLayer()
        }
    }

    public var shadowColor: UIColor? = .black {
        didSet {
            updateLayerUI()
        }
    }

    public var shadowOpacity: Float = 0.5 {
        didSet {
            updateLayerUI()
        }
    }

    public var shadowRadius: CGFloat = 5 {
        didSet {
            updateLayerUI()
        }
    }

    public var shadowOffset: CGSize = CGSize(width: 0, height: 3) {
        didSet {
            updateLayerUI()
        }
    }

    private let shadowLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if shadowLayer.frame != bounds {
            layoutLayer()
        }
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayerUI()
    }

    private func setUpLayer() {
        layer.insertSublayer(shadowLayer, at: 0)

        updateLayerUI()
        layoutLayer()
    }

    private func updateLayerUI() {
        shadowLayer.fillColor = fillColor?.resolvedColor(with: traitCollection).cgColor
        shadowLayer.shadowOpacity = shadowOpacity
        shadowLayer.shadowRadius = shadowRadius
        shadowLayer.shadowColor = shadowColor?.resolvedColor(with: traitCollection).cgColor
        shadowLayer.shadowOffset = shadowOffset
    }

    private func layoutLayer() {
        shadowLayer.frame = bounds
        shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        shadowLayer.shadowPath = shadowLayer.path
    }
}

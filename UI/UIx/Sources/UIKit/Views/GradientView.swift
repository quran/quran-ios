//
//  GradientView.swift
//  UIKitExtension
//
//  Created by Afifi, Mohamed on 3/15/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import UIKit

public class GradientView: UIView {
    // MARK: Lifecycle

    public init(type: CAGradientLayerType) {
        super.init(frame: .zero)
        setUp(type: type)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    override public class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    public var colors: [UIColor] = [] {
        didSet {
            updateColors()
        }
    }

    public var locations: [Double] {
        get { gradientLayer.locations?.map(\.doubleValue) ?? [] }
        set { gradientLayer.locations = newValue.map { NSNumber(value: $0) } }
    }

    public var type: CAGradientLayerType {
        get { gradientLayer.type }
        set { gradientLayer.type = newValue }
    }

    public var startPoint: CGPoint {
        get { gradientLayer.startPoint }
        set { gradientLayer.startPoint = newValue }
    }

    public var endPoint: CGPoint {
        get { gradientLayer.endPoint }
        set { gradientLayer.endPoint = newValue }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if type == .radial {
            layer.cornerRadius = min(bounds.width, bounds.height) / 2
        }
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }

    // MARK: Private

    private var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer // swiftlint:disable:this force_cast
    }

    private func setUp(type: CAGradientLayerType) {
        if type == .radial {
            startPoint = CGPoint(x: 0.5, y: 0.5)
            endPoint = CGPoint(x: 1, y: 1)
        } else {
            startPoint = CGPoint(x: 0, y: 0.5)
            endPoint = CGPoint(x: 1, y: 0.5)
        }
        gradientLayer.type = type
        layer.masksToBounds = true
        colors = [.green, .purple]
    }

    private func updateColors() {
        if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .leftToRight {
            gradientLayer.colors = colors.map(\.cgColor)
        } else {
            gradientLayer.colors = colors.reversed().map(\.cgColor)
        }
    }
}

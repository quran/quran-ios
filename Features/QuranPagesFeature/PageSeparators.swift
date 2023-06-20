//
//  PageSeparators.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-07.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import UIKit
import UIx

class MiddlePageSeparator: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private func setUp() {
        let leftSide = MiddleSidePageSeparator(isLeftSide: true)
        let rightSide = MiddleSidePageSeparator(isLeftSide: false)
        for child in [leftSide, rightSide] {
            addAutoLayoutSubview(child)
            child.vc.verticalEdges()
        }
        leftSide.vc.leading()
        rightSide.vc.trailing()
        addSiblingHorizontalContiguous(left: leftSide, right: rightSide)
    }
}

class MiddleSidePageSeparator: UIView {
    // MARK: Lifecycle

    init(isLeftSide: Bool) {
        super.init(frame: .zero)
        setUp(isLeftSide: isLeftSide)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    static let width: CGFloat = 7
    static let lineWidth: CGFloat = 0.5

    // MARK: Private

    private static let leftSideColors = [UIColor.reading, UIColor.pageSeparatorBackground]

    private let gradientView = GradientView(type: .axial)

    private func setUp(isLeftSide: Bool) {
        let colors = isLeftSide ? Self.leftSideColors : Self.leftSideColors.reversed()
        gradientView.colors = colors

        addAutoLayoutSubview(gradientView)
        gradientView.vc.edges()
        gradientView.vc.width(by: Self.width)

        if isLeftSide {
            let line = UIView()
            line.backgroundColor = UIColor.pageSeparatorLine
            addAutoLayoutSubview(line)
            line.vc.verticalEdges().width(by: Self.lineWidth).trailing()
        }
    }
}

class SidePageSeparator: UIView {
    // MARK: Lifecycle

    private init(colors: [UIColor]) {
        super.init(frame: .zero)
        setUp(colors: colors)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    static let width: CGFloat = 10

    static func leftSide() -> SidePageSeparator {
        SidePageSeparator(colors: leftSideColors)
    }

    static func rightSide() -> SidePageSeparator {
        SidePageSeparator(colors: leftSideColors.reversed())
    }

    // MARK: Private

    private static let leftSideColors = [UIColor.pageSeparatorBackground, UIColor.reading]

    private func setUp(colors: [UIColor]) {
        let gradientView = GradientView(type: .axial)
        gradientView.semanticContentAttribute = .forceLeftToRight
        gradientView.colors = colors
        addAutoLayoutSubview(gradientView)
        gradientView.vc.edges().width(by: Self.width)

        let lines = 5
        for i in 0 ..< lines {
            let step = Self.width / (CGFloat(lines) - 1)
            let distance = CGFloat(i) * step
            let line = UIView()
            line.backgroundColor = UIColor.pageSeparatorLine
            addAutoLayoutSubview(line)
            line.vc.verticalEdges().width(by: 0.5).leading(by: CGFloat(distance))
        }
    }
}

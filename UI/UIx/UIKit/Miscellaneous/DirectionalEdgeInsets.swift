//
//  DirectionalEdgeInsets.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/22/17.
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

public struct DirectionalEdgeInsets {
    // MARK: Lifecycle

    public init(top: CGFloat, bottom: CGFloat, leading: CGFloat, trailing: CGFloat) {
        self.top = top
        self.bottom = bottom
        self.leading = leading
        self.trailing = trailing
    }

    public init(_ insets: UIEdgeInsets, within view: UIView) {
        top = insets.top
        bottom = insets.bottom

        switch view.effectiveUserInterfaceLayoutDirection {
        case .leftToRight:
            leading = insets.left
            trailing = insets.right
        case .rightToLeft:
            leading = insets.right
            trailing = insets.left
        @unknown default:
            fatalError("Unimplemented case")
        }
    }

    public init(_ insets: NSDirectionalEdgeInsets) {
        top = insets.top
        bottom = insets.bottom
        leading = insets.leading
        trailing = insets.trailing
    }

    // MARK: Public

    public var top: CGFloat
    public var bottom: CGFloat
    public var leading: CGFloat
    public var trailing: CGFloat
}

extension DirectionalEdgeInsets {
    public var horizontalInset: CGFloat {
        leading + trailing
    }

    public var verticalInset: CGFloat {
        top + bottom
    }

    public static let zero = DirectionalEdgeInsets(top: 0, bottom: 0, leading: 0, trailing: 0)
}

extension UIView {
    public var directionalLayoutMarginsiOS9: DirectionalEdgeInsets {
        DirectionalEdgeInsets(directionalLayoutMargins)
    }

    public var directionalSafeAreaInsets: DirectionalEdgeInsets {
        DirectionalEdgeInsets(safeAreaInsets, within: self)
    }
}

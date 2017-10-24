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

public struct DirectionalEdgeInsets {

    public var top: CGFloat
    public var bottom: CGFloat
    public var leading: CGFloat
    public var trailing: CGFloat

    public init(top: CGFloat, bottom: CGFloat, leading: CGFloat, trailing: CGFloat) {
        self.top      = top
        self.bottom   = bottom
        self.leading  = leading
        self.trailing = trailing
    }

    public init(_ insets: UIEdgeInsets, within view: UIView) {
        self.top = insets.top
        self.bottom = insets.bottom

        if #available(iOS 10.0, *) {
            switch view.effectiveUserInterfaceLayoutDirection {
            case .leftToRight:
                self.leading = insets.left
                self.trailing = insets.right
            case .rightToLeft:
                self.leading = insets.right
                self.trailing = insets.left
            }
        } else {
            self.leading = insets.left
            self.trailing = insets.right
        }
    }

    @available(iOS 11.0, *)
    public init(_ insets: NSDirectionalEdgeInsets) {
        self.top = insets.top
        self.bottom = insets.bottom
        self.leading = insets.leading
        self.trailing = insets.trailing
    }
}

extension DirectionalEdgeInsets {
    public var horizontalInset: CGFloat {
        return leading + trailing
    }

    public var verticalInset: CGFloat {
        return top + bottom
    }
    public static let zero = DirectionalEdgeInsets(top: 0, bottom: 0, leading: 0, trailing: 0)
}

extension UIView {
    public var directionalLayoutMarginsiOS9: DirectionalEdgeInsets {
        if #available(iOS 11, *) {
            return DirectionalEdgeInsets(directionalLayoutMargins)
        } else {
            return DirectionalEdgeInsets(layoutMargins, within: self)
        }
    }

    public var directionalSafeAreaInsets: DirectionalEdgeInsets {
        if #available(iOS 11, *) {
            return DirectionalEdgeInsets(safeAreaInsets, within: self)
        } else {
            return .zero
        }
    }
}

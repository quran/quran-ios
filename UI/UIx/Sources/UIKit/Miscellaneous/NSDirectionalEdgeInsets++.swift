//
//  NSDirectionalEdgeInsets++.swift
//
//
//  Created by Mohamed Afifi on 2024-01-20.
//

import UIKit

extension UIView {
    public var directionalSafeAreaInsets: NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(safeAreaInsets, within: self)
    }
}

extension NSDirectionalEdgeInsets {
    public init(_ insets: UIEdgeInsets, within view: UIView) {
        let top = insets.top
        let bottom = insets.bottom

        let leading: CGFloat
        let trailing: CGFloat
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

        self.init(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
}

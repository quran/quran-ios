//
//  UITraitCollection+VerticalBar.swift
//
//
//  Created by Mohamed Afifi on 2026-11-24.
//

import UIKit

extension UITraitCollection {
    /// Whether the system shows a vertical bar on a side of the window, like iPhone Duo's in landscape.
    public var hasVerticalBar: Bool {
        verticalBarSide != nil
    }

    /// The window's side, as seen on screen, that the vertical bar is on: `.left` or `.right`, or `nil` without one.
    public var verticalBarSide: UIRectEdge? {
        guard #available(iOS 27.1, *) else {
            return nil
        }
        let isLeading: Bool
        switch verticalBarEdge {
        case .leading: isLeading = true
        case .trailing: isLeading = false
        case .unspecified: return nil
        @unknown default: return nil
        }
        return isLeading == (layoutDirection != .rightToLeft) ? .left : .right
    }
}

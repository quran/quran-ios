//
//  EdgeInsets+LayoutDirection.swift
//

import SwiftUI

extension EdgeInsets {
    /// Insets with physical `left` and `right` placed into leading and trailing for `layoutDirection`.
    public init(top: CGFloat = 0, left: CGFloat, bottom: CGFloat = 0, right: CGFloat, layoutDirection: LayoutDirection) {
        let isRightToLeft = layoutDirection == .rightToLeft
        self.init(
            top: top,
            leading: isRightToLeft ? right : left,
            bottom: bottom,
            trailing: isRightToLeft ? left : right
        )
    }

    /// The physical left inset, when leading and trailing are in `layoutDirection`.
    public func left(in layoutDirection: LayoutDirection) -> CGFloat {
        layoutDirection == .rightToLeft ? trailing : leading
    }

    /// The physical right inset, when leading and trailing are in `layoutDirection`.
    public func right(in layoutDirection: LayoutDirection) -> CGFloat {
        layoutDirection == .rightToLeft ? leading : trailing
    }
}

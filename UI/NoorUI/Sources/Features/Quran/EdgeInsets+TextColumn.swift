//
//  EdgeInsets+TextColumn.swift
//

import QuranGeometry
import SwiftUI
import UIx

extension EdgeInsets {
    /// The space between the content's edges and `textColumn` (image coordinates), for an image fitted to
    /// `imageViewSize` and centred in content `contentWidth` wide.
    init?(
        textColumn: ClosedRange<CGFloat>?,
        imageSize: CGSize,
        imageViewSize: CGSize,
        contentWidth: CGFloat,
        layoutDirection: LayoutDirection
    ) {
        guard let textColumn, imageViewSize.width > 0, contentWidth > 0 else {
            return nil
        }
        let width = textColumn.upperBound - textColumn.lowerBound
        let text = CGRect(x: textColumn.lowerBound, y: 0, width: width, height: 0)
            .scaled(by: WordFrameScale.scaling(imageSize: imageSize, into: imageViewSize))
        // Rounding can make landscape content a hair narrower than the image view.
        let imageMargin = max(0, (contentWidth - imageViewSize.width) / 2)
        let left = imageMargin + max(0, text.minX)
        let right = imageMargin + max(0, imageViewSize.width - text.maxX)
        self.init(left: left, right: right, layoutDirection: layoutDirection)
    }
}

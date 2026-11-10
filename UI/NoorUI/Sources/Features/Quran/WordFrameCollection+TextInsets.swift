//
//  WordFrameCollection+TextInsets.swift
//

import QuranGeometry
import SwiftUI

extension WordFrameCollection {
    /// The horizontal space between the content's edges and the page's text.
    ///
    /// The text's edges are the median edges of its lines, so short lines and marks that overhang
    /// the margin don't move them. The image view is centred in content `contentWidth` wide, and
    /// shows the image fitted to `imageViewSize`.
    func textInsets(
        imageSize: CGSize,
        imageViewSize: CGSize,
        contentWidth: CGFloat,
        layoutDirection: LayoutDirection
    ) -> EdgeInsets? {
        let lines = Dictionary(grouping: frames, by: \.line).values.map { frames in
            frames.map(\.rect).reduce(CGRect.null) { $0.union($1) }
        }
        guard !lines.isEmpty, imageViewSize.width > 0, contentWidth >= imageViewSize.width else {
            return nil
        }
        let minX = Self.median(lines.map(\.minX))
        let text = CGRect(x: minX, y: 0, width: Self.median(lines.map(\.maxX)) - minX, height: 0)
        let textFrame = text.scaled(by: WordFrameScale.scaling(imageSize: imageSize, into: imageViewSize))
        let imageMargin = (contentWidth - imageViewSize.width) / 2
        let left = imageMargin + max(0, textFrame.minX)
        let right = imageMargin + max(0, imageViewSize.width - textFrame.maxX)
        let isRightToLeft = layoutDirection == .rightToLeft
        return EdgeInsets(top: 0, leading: isRightToLeft ? right : left, bottom: 0, trailing: isRightToLeft ? left : right)
    }

    private static func median(_ values: [CGFloat]) -> CGFloat {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}

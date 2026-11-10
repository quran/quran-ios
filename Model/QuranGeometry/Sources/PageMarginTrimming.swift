//
//  PageMarginTrimming.swift
//
//
//  Created by Claude on 2026-11-07.
//

import CoreGraphics

/// Finds the part of a page image to show when its blank margins are trimmed.
///
/// Page images include their own margins. Where the page's height limits its size, like each page of a
/// two-page spread on iPhone Duo, trimming them makes the Quran text bigger.
public enum PageMarginTrimming {
    /// The most to trim from each side, as a fraction of the image's width or height.
    public static let maximumTrim: CGFloat = 0.08
    /// The blank space kept around the content, as a fraction of the image's width or height.
    public static let padding: CGFloat = 0.01

    /// The part of the image to show.
    ///
    /// Trims the same amount from opposite sides so the page stays centered, and never more than
    /// `maximumTrim` of each side, so short pages with centered text don't get zoomed in.
    ///
    /// - Parameters:
    ///   - imageSize: The size of the page image.
    ///   - contentFrames: The frames of the page's words and sura headers, in image coordinates.
    public static func visibleRect(imageSize: CGSize, contentFrames: [CGRect]) -> CGRect {
        let fullImage = CGRect(origin: .zero, size: imageSize)
        guard let first = contentFrames.first, imageSize.width > 0, imageSize.height > 0 else {
            return fullImage
        }
        let content = contentFrames.dropFirst().reduce(first) { $0.union($1) }

        let horizontalTrim = trim(
            leading: content.minX,
            trailing: imageSize.width - content.maxX,
            length: imageSize.width
        )
        let verticalTrim = trim(
            leading: content.minY,
            trailing: imageSize.height - content.maxY,
            length: imageSize.height
        )
        return fullImage.insetBy(dx: horizontalTrim, dy: verticalTrim)
    }

    private static func trim(leading: CGFloat, trailing: CGFloat, length: CGFloat) -> CGFloat {
        let blank = min(leading, trailing) - padding * length
        return max(0, min(blank, maximumTrim * length))
    }
}

extension WordFrameScale {
    /// Scales `visibleRect` of the image to fit the view, centered. The rest of the image falls outside the view.
    public static func scaling(imageSize: CGSize, visibleRect: CGRect, into viewSize: CGSize) -> WordFrameScale {
        let visible = scaling(imageSize: visibleRect.size, into: viewSize)
        guard visible.scale > 0 else {
            return .zero
        }
        return WordFrameScale(
            scale: visible.scale,
            xOffset: visible.xOffset - visibleRect.minX * visible.scale,
            yOffset: visible.yOffset - visibleRect.minY * visible.scale
        )
    }
}

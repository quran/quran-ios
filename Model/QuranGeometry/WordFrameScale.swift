//
//  WordFrameScale.swift
//
//
//  Created by Mohamed Afifi on 2023-06-10.
//

import CoreGraphics

public struct WordFrameScale {
    // MARK: Lifecycle

    public init(scale: CGFloat, xOffset: CGFloat, yOffset: CGFloat) {
        self.scale = scale
        self.xOffset = xOffset
        self.yOffset = yOffset
    }

    // MARK: Public

    public static let zero = WordFrameScale(scale: 0, xOffset: 0, yOffset: 0)

    public let scale: CGFloat
    public let xOffset: CGFloat
    public let yOffset: CGFloat
}

extension WordFrameScale {
    public static func scaling(imageSize: CGSize, into viewSize: CGSize) -> WordFrameScale {
        // Return zero scaling if either size is zero
        if imageSize == .zero || viewSize == .zero {
            return .zero
        }

        // Calculate the scaling factor to fit the image within the view while maintaining aspect ratio
        let scale: CGFloat
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewAspectRatio = viewSize.width / viewSize.height
        if imageAspectRatio < viewAspectRatio {
            // Image is taller relative to the view, fit by height
            scale = viewSize.height / imageSize.height
        } else {
            // Image is wider relative to the view, fit by width
            scale = viewSize.width / imageSize.width
        }

        // Calculate offsets to center the image within the view
        let xOffset = (viewSize.width - (scale * imageSize.width)) / 2
        let yOffset = (viewSize.height - (scale * imageSize.height)) / 2
        return WordFrameScale(scale: scale, xOffset: xOffset, yOffset: yOffset)
    }
}

extension CGRect {
    public func scaled(by scale: WordFrameScale) -> CGRect {
        CGRect(
            x: minX * scale.scale + scale.xOffset,
            y: minY * scale.scale + scale.yOffset,
            width: width * scale.scale,
            height: height * scale.scale
        )
    }
}

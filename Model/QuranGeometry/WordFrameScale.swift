//
//  WordFrameScale.swift
//
//
//  Created by Mohamed Afifi on 2023-06-10.
//

import Foundation

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
    public static func scaling(imageSize: CGSize, into imageViewSize: CGSize) -> WordFrameScale {
        if imageSize == .zero || imageViewSize == .zero {
            return .zero
        }

        let scale: CGFloat
        if imageSize.width / imageSize.height < imageViewSize.width / imageViewSize.height {
            scale = imageViewSize.height / imageSize.height
        } else {
            scale = imageViewSize.width / imageSize.width
        }
        let xOffset = (imageViewSize.width - (scale * imageSize.width)) / 2
        let yOffset = (imageViewSize.height - (scale * imageSize.height)) / 2
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

//
//  WordFrameScale.swift
//
//
//  Created by Mohamed Afifi on 2021-12-26.
//

import UIKit

public struct WordFrameScale {
    let scale: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat

    public static let zero = WordFrameScale(scale: 0, xOffset: 0, yOffset: 0)

    public static func scaling(imageSize: CGSize, into imageViewSize: CGSize) -> WordFrameScale {
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
        CGRect(x: minX * scale.scale + scale.xOffset,
               y: minY * scale.scale + scale.yOffset,
               width: width * scale.scale,
               height: height * scale.scale)
    }
}

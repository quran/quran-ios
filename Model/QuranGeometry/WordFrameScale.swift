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

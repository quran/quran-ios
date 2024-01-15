//
//  FontSize++.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/18.
//

import QuranText
import UIKit

extension FontSize: Strideable {
    public func distance(to other: FontSize) -> Int {
        Stride(other.rawValue) - Stride(rawValue)
    }

    public func advanced(by n: Int) -> FontSize {
        FontSize(rawValue: Stride(rawValue) + n)!
    }
}

extension FontSize {
    func fontSize(forMediumSize size: CGFloat) -> CGFloat {
        let factor: CGFloat
        switch self {
        case .xxSmall: factor = 0.7 * 0.7 * 0.7
        case .xSmall: factor = 0.7 * 0.7
        case .small: factor = 0.7
        case .medium: factor = 1
        case .large: factor = 1 / 0.8
        case .xLarge: factor = 1 / 0.8 / 0.8
        case .xxLarge: factor = 1 / 0.8 / 0.8 / 0.8
        }
        return size * factor
    }
}

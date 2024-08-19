//
//  FontSize++.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/18.
//

import CoreFoundation
import QuranText

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
        let factor: CGFloat = switch self {
        case .xxSmall: 0.7 * 0.7 * 0.7
        case .xSmall: 0.7 * 0.7
        case .small: 0.7
        case .medium: 1
        case .large: 1 / 0.8
        case .xLarge: 1 / 0.8 / 0.8
        case .xxLarge: 1 / 0.8 / 0.8 / 0.8
        }
        return size * factor
    }
}

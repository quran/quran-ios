//
//  FontSize++.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/18.
//

import CoreFoundation
import QuranText

extension FontSize {
    func fontSize(forMediumSize size: CGFloat) -> CGFloat {
        let factor: CGFloat = switch self {
        case .xSmall: 0.7 * 0.7 * 0.7
        case .small: 0.7 * 0.7
        case .medium: 0.7
        case .large: 1
        case .xLarge: 1 / 0.8
        case .xxLarge: 1 / 0.8 / 0.8
        case .xxxLarge: 1 / 0.8 / 0.8 / 0.8
        case .accessibility1: 1 / 0.8 / 0.8 / 0.8 / 0.8
        case .accessibility2: 1 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8
        case .accessibility3: 1 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8
        case .accessibility4: 1 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8
        case .accessibility5: 1 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8 / 0.8
        }
        return size * factor
    }
}

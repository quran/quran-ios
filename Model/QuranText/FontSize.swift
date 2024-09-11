//
//  FontSize.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/18.
//

import SwiftUI

public enum FontSize: Int, CaseIterable, CustomStringConvertible {
    case accessibility5 = -6
    case accessibility4 = -5
    case accessibility3 = -4
    case accessibility2 = -3
    case accessibility1 = -2
    case xxxLarge = -1
    case xxLarge = 0
    case xLarge = 1
    case large = 2
    case medium = 3
    case small = 4
    case xSmall = 5

    // MARK: Public

    public var description: String {
        switch self {
        case .accessibility5: "accessibility5"
        case .accessibility4: "accessibility4"
        case .accessibility3: "accessibility3"
        case .accessibility2: "accessibility2"
        case .accessibility1: "accessibility1"
        case .xxxLarge: "xxxLarge"
        case .xxLarge: "xxLarge"
        case .xLarge: "xLarge"
        case .large: "large"
        case .medium: "medium"
        case .small: "small"
        case .xSmall: "xSmall"
        }
    }
}

extension FontSize {
    public var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .accessibility5: .accessibility5
        case .accessibility4: .accessibility4
        case .accessibility3: .accessibility3
        case .accessibility2: .accessibility2
        case .accessibility1: .accessibility1
        case .xxxLarge: .xxxLarge
        case .xxLarge: .xxLarge
        case .xLarge: .xLarge
        case .large: .large
        case .medium: .medium
        case .small: .small
        case .xSmall: .xSmall
        }
    }
}

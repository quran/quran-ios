//
//  FontSize.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/18.
//

import SwiftUI

public enum FontSize: Int, CaseIterable, CustomStringConvertible {
    case xxLarge = -1
    case xLarge = 0
    case large = 1
    case medium = 2
    case small = 3
    case xSmall = 4
    case xxSmall = 5

    // MARK: Public

    public var description: String {
        switch self {
        case .xxLarge: return "xxLarge"
        case .xLarge: return "xLarge"
        case .large: return "large"
        case .medium: return "medium"
        case .small: return "small"
        case .xSmall: return "xSmall"
        case .xxSmall: return "xxSmall"
        }
    }
}

extension FontSize {
    public var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .xxLarge: .xxxLarge
        case .xLarge: .xxLarge
        case .large: .xLarge
        case .medium: .large
        case .small: .medium
        case .xSmall: .small
        case .xxSmall: .xSmall
        }
    }
}

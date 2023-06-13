//
//  FontSize.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/18.
//

public enum FontSize: Int, CaseIterable, CustomStringConvertible {
    case xxLarge = -1
    case xLarge = 0
    case large = 1
    case medium = 2
    case small = 3
    case xSmall = 4
    case xxSmall = 5

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

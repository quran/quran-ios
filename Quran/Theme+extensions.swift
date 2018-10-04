//
//  Theme+extensions.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation

extension Theme {
    fileprivate func color(lightGray: CGFloat) -> UIColor {
        switch self {
        case .dark:  return UIColor(white: 1 - lightGray, alpha: 1)
        case .light: return UIColor(white: lightGray, alpha: 1)
        }
    }
}

extension Theme {
    private static let persistence = Container().createSimplePersistence()
    static var current: Theme { return persistence.theme }
}

extension Theme {
    enum Kind {
        // labels
        case label
        case labelVeryStrong
        case labelStrong
        case labelMedium
        case labelWeak
        case labelVeryWeak
        case labelExtremelyWeak

        // general
        case backgroundOLED
        case background
        case separator
        case appTint
        case appBarsTint
        case appBarButtonsTint
        case none

        // popover
        case popover
        case popoverSeparator

        // cell
        case cell
        case cellSelected

        // specific
        case readerImageBorder
        case suraHeader
        case dimmed

        var color: UIColor {
            switch self {
            case .label:              return Theme.current.color(lightGray: 0.00)
            case .labelVeryStrong:    return Theme.current.color(lightGray: 0.10)
            case .labelStrong:        return Theme.current.color(lightGray: 0.20)
            case .labelMedium:        return Theme.current.color(lightGray: 0.30)
            case .labelWeak:          return Theme.current.color(lightGray: 0.40)
            case .labelVeryWeak:      return Theme.current.color(lightGray: 0.70)
            case .labelExtremelyWeak: return Theme.current.color(lightGray: 0.85)

            case .popover:          return Theme.current == .dark ? Theme.current.color(lightGray: 0.80) : .white
            case .popoverSeparator: return Theme.current.color(lightGray: 0.90)

            case .backgroundOLED:    return .backgroundOLED
            case .background:        return Theme.current.color(lightGray: 0.94)
            case .separator:         return Theme.current.color(lightGray: 0.78)
            case .appTint:           return .buttonsTint
            case .appBarsTint:       return .barsBackground
            case .appBarButtonsTint: return .barButtonsTint
            case .none:              return .clear

            case .cell:         return Theme.current.color(lightGray: 1.00)
            case .cellSelected: return Theme.current.color(lightGray: 0.70)

            case .readerImageBorder: return Theme.current.color(lightGray: 0.67)
            case .suraHeader:        return .suraHeader
            case .dimmed:            return UIColor.black.withAlphaComponent(0.30)
            }
        }
    }
}

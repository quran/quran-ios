//
//  UIColor+Theme.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/20/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
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

import UIKit

extension UIColor {

    class func appIdentity() -> UIColor {
        return #colorLiteral(red: 0.1058823529, green: 0.4196078431, blue: 0.4431372549, alpha: 1)
    }

    class func bookmark() -> UIColor {
        return #colorLiteral(red: 1, green: 0.3921568627, blue: 0.3921568627, alpha: 1)
    }

    class func selection() -> UIColor {
        return #colorLiteral(red: 0.08235294118, green: 0.4274509804, blue: 0.8705882353, alpha: 1)
    }

    static var barsBackground: UIColor {
        switch Theme.current {
        case .dark:  return #colorLiteral(red: 0.01194690265, green: 0.04746312684, blue: 0.05, alpha: 1)
        case .light: return .appIdentity()
        }
    }

    static var searchBarBackground: UIColor {
        switch Theme.current {
        case .dark:  return .barsBackground
        case .light: return #colorLiteral(red: 0.0716814159, green: 0.2847787611, blue: 0.3, alpha: 1)
        }
    }

    static var barButtonsTint: UIColor {
        switch Theme.current {
        case .dark:  return .buttonsTint
        case .light: return .white
        }
    }

    static var buttonsTint: UIColor {
        switch Theme.current {
        case .dark:  return #colorLiteral(red: 0.1672566371, green: 0.6628318584, blue: 0.7, alpha: 1)
        case .light: return .appIdentity()
        }
    }

    static var suraHeader: UIColor {
        switch Theme.current {
        case .dark:  return #colorLiteral(red: 0.08235294118, green: 0.3215686275, blue: 0.3411764706, alpha: 1)
        case .light: return #colorLiteral(red: 0.08235294118, green: 0.3215686275, blue: 0.3411764706, alpha: 1)
        }
    }

    static var backgroundOLED: UIColor {
        switch Theme.current {
        case .dark:  return UIColor.black
        case .light: return #colorLiteral(red: 0.9521597028, green: 0.9521597028, blue: 0.9521597028, alpha: 1)
        }
    }
}

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
        return UIColor(rgb: 0x1B6B71)
    }

    class func secondaryColor() -> UIColor {
        return UIColor.white
    }

    class func readingBackground() -> UIColor {
        return UIColor(rgb: 0xF5F5F5)
    }

    class func bookmark() -> UIColor {
        return UIColor(r: 255, g: 100, b: 100)
    }

    class func selection() -> UIColor {
        return UIColor(rgb: 0x156DDE)
    }

    static var translationText: UIColor {
        return #colorLiteral(red: 0.03921568627, green: 0.03921568627, blue: 0.03921568627, alpha: 1)
    }

    static var translatorName: UIColor {
        return #colorLiteral(red: 0.5490196078, green: 0.662745098, blue: 0.662745098, alpha: 1)
    }
}

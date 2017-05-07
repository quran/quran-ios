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

    class func secondaryColor() -> UIColor {
        return UIColor.white
    }

    class func readingBackground() -> UIColor {
        return #colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1)
    }

    class func bookmark() -> UIColor {
        return #colorLiteral(red: 1, green: 0.3921568627, blue: 0.3921568627, alpha: 1)
    }

    class func selection() -> UIColor {
        return #colorLiteral(red: 0.08235294118, green: 0.4274509804, blue: 0.8705882353, alpha: 1)
    }

    static var translationText: UIColor {
        return #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
    }

    static var translatorName: UIColor {
        return #colorLiteral(red: 0.5490196078, green: 0.662745098, blue: 0.662745098, alpha: 1)
    }
}

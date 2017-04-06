//
//  UIColor+Theme.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
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

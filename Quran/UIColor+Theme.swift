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
}

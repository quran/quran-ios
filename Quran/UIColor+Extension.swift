//
//  UIColor+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

extension UIColor {

    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    convenience init(gray: CGFloat, a: CGFloat = 1) {
        self.init(r: gray, g: gray, b: gray, a: a)
    }

    convenience init(rgb: Int) {
        self.init(r: CGFloat((rgb >> 16) & 0xff),
                  g: CGFloat((rgb >> 08) & 0xff),
                  b: CGFloat((rgb >> 00) & 0xff))
    }

    /**
     Creates a 1 pixel image from the color.

     - returns: The 1 pixel image of the color.
     */
    func image() -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

//
//  UIBezierPath+Extension.swift
//
//
//  Created by Afifi, Mohamed on 12/6/20.
//

import UIKit

extension UIBezierPath {
    /** Returns an image of the path drawn using a stroke */
    public func image(strokeColor: UIColor?, fillColor: UIColor?) -> UIImage? {
        let size = CGSize(width: bounds.size.width + lineWidth,
                          height: bounds.size.width + lineWidth)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()

        // translate matrix so that path will be centered in bounds
        context?.translateBy(x: lineWidth / 2, y: lineWidth / 2)

        // draw
        if let fillColor {
            fillColor.setFill()
            fill()
        }

        if let strokeColor {
            strokeColor.setStroke()
            stroke()
        }

        // grab an image of the context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

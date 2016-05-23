//
//  UIImage+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/4/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

extension UIImage {

    func preloadedImage() -> UIImage {

        // make a bitmap context of a suitable size to draw to, forcing decode
        let width = CGImageGetWidth(CGImage)
        let height = CGImageGetHeight(CGImage)

        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let imageContext =  CGBitmapContextCreate(nil,
                                                  width,
                                                  height,
                                                  8,
                                                  width * 4,
                                                  colourSpace,
                                                  CGImageAlphaInfo.PremultipliedFirst.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue)

        // draw the image to the context, release it
        CGContextDrawImage(imageContext, CGRect(x: 0, y: 0, width: width, height: height), CGImage)

        // now get an image ref from the context
        if let outputImage = CGBitmapContextCreateImage(imageContext) {
            let cachedImage = UIImage(CGImage: outputImage)
            return cachedImage
        }
        return self
    }
}

//
//  UIImage+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/4/16.
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

import UIKit

extension UIImage {

    public func preloadedImage() -> UIImage {

        guard let cgimg = cgImage else {
            return self
        }

        // make a bitmap context of a suitable size to draw to, forcing decode
        let width = cgimg.width
        let height = cgimg.height

        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let imageContext = CGContext(data: nil,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: 8,
                                     bytesPerRow: width * 4,
                                     space: colourSpace,
                                     bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

        // draw the image to the context, release it
        imageContext?.draw(cgimg, in: CGRect(x: 0, y: 0, width: width, height: height))

        // now get an image ref from the context
        if let outputImage = imageContext?.makeImage() {
            let cachedImage = UIImage(cgImage: outputImage)
            return cachedImage
        }
        return self
    }

    public func tintedImage(withColor color: UIColor) -> UIImage? {
        guard let cgImage = cgImage else { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: size.height)
        context?.scaleBy(x: 1, y: -1)
        context?.setBlendMode(.normal)
        let rect = CGRect(origin: .zero, size: size)
        context?.clip(to: rect, mask: cgImage)
        color.setFill()
        context?.fill(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

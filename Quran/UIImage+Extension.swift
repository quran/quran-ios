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

        guard let cgimg = cgImage else {
            return self
        }

        // make a bitmap context of a suitable size to draw to, forcing decode
        let width = cgimg.width
        let height = cgimg.height

        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let imageContext =  CGContext(data: nil,
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
}

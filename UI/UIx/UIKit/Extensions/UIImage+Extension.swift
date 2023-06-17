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
    public func tintedImage(withColor color: UIColor) -> UIImage? {
        guard let cgImage else { return nil }

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

    public func rounded(by cornerRadius: CGFloat) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        path.addClip()
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    public func rotate(by radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContext(newSize)
        let context = UIGraphicsGetCurrentContext()

        // Move origin to middle
        context?.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate around middle
        context?.rotate(by: CGFloat(radians))

        draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    public func scaled(toHeight height: CGFloat) -> UIImage? {
        let width = height / size.height * size.width
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, scale)
        draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height)))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    public func inverted() -> UIImage {
        guard let filter = CIFilter(name: "CIColorInvert") else {
            return self
        }
        filter.setDefaults()
        filter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else {
            return self
        }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return self
        }
        return UIImage(cgImage: cgImage)
    }

    public static func canavas(size: CGSize, drawing images: [(image: UIImage, origin: CGPoint)]) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        for (image, origin) in images {
            image.draw(at: origin)
        }

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    @available(iOS 13.0, *)
    public static func symbol(_ name: String) -> UIImage {
        UIImage(systemName: name)!
    }

    @available(iOS 13.0, *)
    public static func symbol(_ name: String, withConfiguration configuration: UIImage.Configuration?) -> UIImage {
        UIImage(systemName: name, withConfiguration: configuration)!
    }

    public static func filledImage(fillColor: UIColor, radius: CGFloat, lineColor: UIColor, lineWidth: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: radius * 2, height: radius * 2), false, 0)

        let bezierPath = UIBezierPath(
            roundedRect: CGRect(
                x: lineWidth,
                y: lineWidth,
                width: (radius - lineWidth) * 2,
                height: (radius - lineWidth) * 2
            ),
            cornerRadius: radius
        )
        bezierPath.lineWidth = lineWidth

        lineColor.setStroke()
        fillColor.setFill()

        bezierPath.stroke()
        bezierPath.fill()

        let image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return image?.resizableImage(withCapInsets: UIEdgeInsets(top: radius, left: radius, bottom: radius, right: radius))
    }
}

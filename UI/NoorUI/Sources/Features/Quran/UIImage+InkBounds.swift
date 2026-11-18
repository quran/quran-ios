//
//  UIImage+InkBounds.swift
//
//
//  Created by Mohamed Afifi on 2026-11-18.
//

import UIKit

extension UIImage {
    /// The smallest rect, in the image's point coordinates, that holds all of the page's ink: text, and chrome that
    /// some readings draw into the image, like sura header frames, which no word frame covers.
    ///
    /// Measured on a small copy of the image and rounded outward, so it may be a few points larger, never smaller.
    /// Cached per image; only iPhone Duo's margin trimming asks for it.
    var quranPageInkBounds: CGRect? {
        if let cached = Self.inkBoundsCache.object(forKey: self) {
            return cached.rect
        }
        let bounds = measureInkBounds()
        Self.inkBoundsCache.setObject(InkBounds(rect: bounds), forKey: self)
        return bounds
    }

    // MARK: Private

    private final class InkBounds {
        init(rect: CGRect?) {
            self.rect = rect
        }

        let rect: CGRect?
    }

    private static let inkBoundsCache = NSCache<UIImage, InkBounds>()

    /// Ink is any sample darker than near white, out of 255, so thin lines and anti-aliased edges count.
    private static let inkThreshold: UInt8 = 245
    private static let sampleWidth = 256

    private func measureInkBounds() -> CGRect? {
        guard let cgImage, cgImage.width > 0, cgImage.height > 0, size.width > 0, size.height > 0 else {
            return nil
        }
        let width = min(Self.sampleWidth, cgImage.width)
        let height = max(1, Int((CGFloat(cgImage.height) * CGFloat(width) / CGFloat(cgImage.width)).rounded()))
        var pixels = [UInt8](repeating: 255, count: width * height)
        let drew = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else {
                return false
            }
            // Pages are dark ink on a clear or white background.
            context.setFillColor(gray: 1, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.interpolationQuality = .medium
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drew else {
            return nil
        }

        var minX = width, minY = height, maxX = -1, maxY = -1
        for row in 0 ..< height {
            let offset = row * width
            for column in 0 ..< width where pixels[offset + column] < Self.inkThreshold {
                minX = min(minX, column)
                maxX = max(maxX, column)
                minY = min(minY, row)
                maxY = max(maxY, row)
            }
        }
        guard maxX >= minX, maxY >= minY else {
            return nil
        }
        // Bitmap rows run top to bottom, like the image. Round out by one sample on every side.
        let xScale = size.width / CGFloat(width)
        let yScale = size.height / CGFloat(height)
        let rect = CGRect(
            x: CGFloat(minX - 1) * xScale,
            y: CGFloat(minY - 1) * yScale,
            width: CGFloat(maxX - minX + 3) * xScale,
            height: CGFloat(maxY - minY + 3) * yScale
        )
        return rect.intersection(CGRect(origin: .zero, size: size))
    }
}

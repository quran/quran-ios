//
//  PageBitmap.swift
//

import CoreGraphics

/// A page or line image decoded into a 32-bit premultiplied BGRA bitmap: drawing it needs no further decoding,
/// and its pixels tell where the ink is.
struct PageBitmap {
    // MARK: Lifecycle

    init?(_ image: CGImage) {
        let width = image.width
        let height = image.height
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ), let pixels = context.data else {
            return nil
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let decoded = context.makeImage() else {
            return nil
        }
        self.image = decoded
        self.context = context
        self.pixels = UnsafeRawPointer(pixels)
        self.width = width
        self.height = height
        bytesPerRow = context.bytesPerRow
    }

    // MARK: Internal

    let image: CGImage

    /// `rect` narrowed horizontally to the ink in its rows, scanning in from each side; nil when it holds none.
    func inkExtent(in rect: CGRect) -> CGRect? {
        let top = max(0, Int(rect.minY.rounded(.down)))
        let bottom = min(height, Int(rect.maxY.rounded(.up)))
        let left = max(0, Int(rect.minX.rounded(.down)))
        let right = min(width, Int(rect.maxX.rounded(.up)))
        guard top < bottom, left < right else {
            return nil
        }
        let rows = top ..< bottom
        let columns = left ..< right
        let hasInk = { (x: Int) in rows.contains { isInk(x: x, y: $0) } }
        guard let inkLeft = columns.first(where: hasInk), let inkRight = columns.reversed().first(where: hasInk) else {
            return nil
        }
        return CGRect(x: CGFloat(inkLeft), y: rect.minY, width: CGFloat(inkRight + 1 - inkLeft), height: rect.height)
    }

    // MARK: Private

    /// Owns the memory `pixels` points to.
    private let context: CGContext
    private let pixels: UnsafeRawPointer
    private let width: Int
    private let height: Int
    private let bytesPerRow: Int

    /// At least half opaque and not near-white: pages draw dark or coloured (Tajweed) glyphs on either a transparent
    /// background, which fails the alpha test, or an opaque white one, which fails the colour test.
    private func isInk(x: Int, y: Int) -> Bool {
        let pixel = pixels + y * bytesPerRow + x * 4
        let alpha = Int(pixel.load(fromByteOffset: 3, as: UInt8.self))
        let darkest = Int(min(
            pixel.load(fromByteOffset: 0, as: UInt8.self),
            pixel.load(fromByteOffset: 1, as: UInt8.self),
            pixel.load(fromByteOffset: 2, as: UInt8.self)
        ))
        // Premultiplied, so the darkest channel is below 3/4 intensity when it is below 3/4 of the alpha.
        return alpha >= 128 && darkest * 4 < alpha * 3
    }
}

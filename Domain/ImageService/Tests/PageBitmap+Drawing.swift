//
//  PageBitmap+Drawing.swift
//

import UIKit
import XCTest
@testable import ImageService

extension PageBitmap {
    /// A page drawing each group of rects, top-left origin, in its colour.
    static func drawn(
        size: CGSize = CGSize(width: 200, height: 100),
        background: UIColor = .clear,
        glyphs: [([CGRect], UIColor)]
    ) throws -> PageBitmap {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            background.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            for (rects, color) in glyphs {
                color.setFill()
                context.cgContext.fill(rects)
            }
        }
        return try XCTUnwrap(PageBitmap(XCTUnwrap(image.cgImage)))
    }
}

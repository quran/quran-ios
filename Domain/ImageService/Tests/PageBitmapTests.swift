//
//  PageBitmapTests.swift
//

import UIKit
import XCTest
@testable import ImageService

final class PageBitmapTests: XCTestCase {
    func testInkOnATransparentBackgroundIsItsDarkGlyphs() throws {
        let bitmap = try PageBitmap.drawn(glyphs: [(glyphs, .black)])

        XCTAssertEqual(bitmap.inkExtent(in: paddedLine), inkLine)
    }

    func testInkOnAnOpaqueWhiteBackgroundIsItsDarkGlyphs() throws {
        let bitmap = try PageBitmap.drawn(background: .white, glyphs: [(glyphs, .black)])

        XCTAssertEqual(bitmap.inkExtent(in: paddedLine), inkLine)
    }

    func testColouredGlyphsAreInk() throws {
        // Tajweed pages colour some letters, such as the line's outermost ones.
        let bitmap = try PageBitmap.drawn(background: .white, glyphs: [
            ([glyphs[0]], UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)),
            ([glyphs[1]], UIColor(red: 0.1, green: 0.6, blue: 0.2, alpha: 1)),
        ])

        XCTAssertEqual(bitmap.inkExtent(in: paddedLine), inkLine)
    }

    func testInkOutsideTheLineRowsDoesNotWidenIt() throws {
        let nextLine = CGRect(x: 5, y: 70, width: 190, height: 20)
        let bitmap = try PageBitmap.drawn(glyphs: [(glyphs + [nextLine], .black)])

        XCTAssertEqual(bitmap.inkExtent(in: paddedLine), inkLine)
    }

    func testALineWithoutInkHasNoInkExtent() throws {
        let bitmap = try PageBitmap.drawn(background: .white, glyphs: [])

        XCTAssertNil(bitmap.inkExtent(in: paddedLine))
    }

    // MARK: Private

    /// Two words of a line, top-left origin.
    private let glyphs = [
        CGRect(x: 30, y: 25, width: 40, height: 20),
        CGRect(x: 120, y: 20, width: 50, height: 30),
    ]
    private let paddedLine = CGRect(x: 10, y: 15, width: 180, height: 40)
    private let inkLine = CGRect(x: 30, y: 15, width: 140, height: 40)
}

extension PageBitmap {
    /// A page `size` wide and tall, top-left origin, drawing each group of rects in its colour.
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

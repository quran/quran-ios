//
//  DecoratedSuraNameLabelTests.swift
//

import NoorFont
import QuranKit
import UIKit
import XCTest
@testable import NoorUI

/// UIKit labels, like the Bookmarks and reader titles, show sura names through `MultipartText.attributedString`.
@MainActor
final class DecoratedSuraNameLabelTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
    }

    /// A label draws only inside its bounds, so a label sized to fit its text must hold the glyphs' ink.
    func test_label_sizedToFit_holdsTheGlyphInk() throws {
        for size in [MultipartText.FontSize.body, .subheadline] {
            for sura in Quran.hafsMadani1405.suras {
                let text = MultipartText("\(sura: sura)").attributedString(ofSize: size, locale: arabic)
                let ink = try render(text)
                let rows = zip(ink.glyph, ink.text).map { $0 + $1 }
                let bottom = try XCTUnwrap(rows.firstIndex { $0 > 0 })
                let top = try XCTUnwrap(rows.lastIndex { $0 > 0 })
                let labelBottom = Int((margin * scale).rounded())
                let labelTop = labelBottom + Int((ink.labelHeight * scale).rounded(.up))

                // A pixel-snapped baseline can leave an antialiased pixel row of the tallest glyphs outside the label.
                XCTAssertGreaterThanOrEqual(bottom, labelBottom - 1, "\(size) \(sura.suraNumber)")
                XCTAssertLessThanOrEqual(top, labelTop, "\(size) \(sura.suraNumber)")
            }
        }
    }

    /// The same check as `DecoratedSuraNameGlyphTests`' writing-line test, on what a label draws: the glyphs sit
    /// on the line of the Arabic text beside them, with no baseline offset.
    func test_label_putsTheGlyphsOnTheWritingLineOfTheTextBesideThem() throws {
        for size in [MultipartText.FontSize.body, .subheadline] {
            let offsets = try Quran.hafsMadani1405.suras.map { sura in
                let text = MultipartText.format("سورة %@ الصفحة", arguments: ["\(sura: sura)"])
                let ink = try render(text.attributedString(ofSize: size, locale: arabic))
                let glyphLine = try writingLineRow(inkPerRow: ink.glyph, pixelsPerEm: size.suraUIFont.pointSize * scale)
                let textLine = try writingLineRow(inkPerRow: ink.text, pixelsPerEm: size.plainUIFont.pointSize * scale)
                return (glyphLine - textLine) / scale
            }

            XCTAssertEqual(median(offsets), 0, accuracy: 0.2, "\(size)")
        }
    }

    // MARK: Private

    private let arabic = Locale(identifier: "ar")
    private let scale: CGFloat = 4
    private let margin: CGFloat = 10

    /// The glyphs' and the text's ink per pixel row, from the bottom, of a label sized to fit `text`, drawn with
    /// `margin` around it.
    private func render(_ text: NSAttributedString) throws -> (glyph: [Int], text: [Int], labelHeight: CGFloat) {
        let colored = NSMutableAttributedString(attributedString: text)
        let range = NSRange(location: 0, length: colored.length)
        colored.addAttribute(.foregroundColor, value: UIColor.black, range: range)
        colored.enumerateAttribute(.font, in: range) { font, range, _ in
            if (font as? UIFont)?.fontName == UIFont(.suraNames, size: 20).fontName {
                colored.addAttribute(.foregroundColor, value: UIColor.red, range: range)
            }
        }
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = colored
        let fitting = label.sizeThatFits(CGSize(width: 1000, height: CGFloat.greatestFiniteMagnitude))
        // A taller label centres the same line, so it draws all the ink that would overflow the fitting label.
        label.frame = CGRect(x: 0, y: 0, width: fitting.width, height: fitting.height + 2 * margin)
        label.layer.displayIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let image = UIGraphicsImageRenderer(size: label.bounds.size, format: format).image { context in
            label.layer.render(in: context.cgContext)
        }
        let cgImage = try XCTUnwrap(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = try XCTUnwrap(CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var glyph = [Int](repeating: 0, count: height)
        var plain = [Int](repeating: 0, count: height)
        for row in 0 ..< height {
            for column in 0 ..< width {
                let pixel = (row * width + column) * 4
                let alpha = Int(pixels[pixel + 3])
                guard alpha > 0 else { continue }
                // Premultiplied red keeps its red channel near its alpha; black keeps it near 0.
                if Int(pixels[pixel]) * 2 > alpha {
                    glyph[height - 1 - row] += alpha
                } else {
                    plain[height - 1 - row] += alpha
                }
            }
        }
        return (glyph, plain, fitting.height)
    }
}

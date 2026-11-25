//
//  DecoratedSuraNameGlyphTests.swift
//

import CoreText
import NoorFont
import QuranKit
import UIKit
import XCTest
@testable import NoorUI

/// `Tools/tighten-sura-name-glyphs.py` makes the decorated sura names sit flush in their boxes, like regular text,
/// lowers them onto the system font's Arabic writing line, and fits the font's line box to their ink.
final class DecoratedSuraNameGlyphTests: XCTestCase {
    override func setUp() {
        super.setUp()
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
    }

    func test_suraGlyphs_haveNoSideBearings() throws {
        for sura in Quran.hafsMadani1405.suras {
            let character = try XCTUnwrap(QuranReference.sura(sura).rawValue(locale: Locale(identifier: "ar")).utf16.first)
            let metrics = try metrics(of: character)

            XCTAssertEqual(metrics.ink.minX, 0, accuracy: 0.1, "\(sura.suraNumber) left side bearing")
            XCTAssertEqual(metrics.advance - metrics.ink.maxX, 0, accuracy: 0.1, "\(sura.suraNumber) right side bearing")
        }
    }

    func test_otherGlyphs_keepTheirMetrics() throws {
        // 0xE903 is in the sura range but names no sura.
        let unused = try metrics(of: 0xE903)

        XCTAssertEqual(unused.advance, 21.52, accuracy: 0.01)
        XCTAssertEqual(unused.ink.minX, 1.23, accuracy: 0.01)
        XCTAssertEqual(try metrics(of: 0x20).advance, 16, accuracy: 0.01)
    }

    /// Baseline alignment puts the glyphs' baseline on the text's, so where each font draws its letters above its
    /// baseline decides whether they look level.
    func test_suraGlyphs_sitOnTheWritingLineOfTheArabicTextBesideThem() throws {
        let glyphLines = try suraGlyphInk(at: Self.measuringSize).map { try writingLine(of: $0) }
        let textLines = try ["الصفحة", "عند", "سورة البقرة", "بسم الله الرحمن الرحيم"].map { try writingLine(of: arabicTextPath($0)) }
        let glyphLine = median(glyphLines)
        let textLine = median(textLines)

        for size in [MultipartText.FontSize.caption, .footnote, .subheadline, .body, .title3] {
            let offset = glyphLine * size.suraUIFont.pointSize - textLine * size.plainUIFont.pointSize
            XCTAssertEqual(offset, 0, accuracy: 0.2, "\(size): glyphs \(glyphLine) em, text \(textLine) em")
        }
    }

    /// A view that centres a glyph's line box then centres the typical glyph's ink.
    func test_lineBoxMiddle_isTheGlyphsMedianInkCenter() throws {
        // At 1024 pt, a point is a font unit.
        let font = UIFont(.suraNames, size: 1024) as CTFont
        let centers = try suraGlyphInk(at: 1024).map(\.boundingBoxOfPath.midY)
        let lineBoxMiddle = (CTFontGetAscent(font) - CTFontGetDescent(font)) / 2

        XCTAssertEqual(lineBoxMiddle, median(centers), accuracy: 3)
        XCTAssertEqual(CTFontGetLeading(font), 0)
    }

    /// The glyphs need no padding: their line box holds all their ink.
    func test_suraGlyphs_fitTheirInkInTheirLineBox() throws {
        let font = UIFont(.suraNames, size: 1024) as CTFont
        for (sura, ink) in try zip(Quran.hafsMadani1405.suras, suraGlyphInk(at: 1024).map(\.boundingBoxOfPath)) {
            XCTAssertLessThanOrEqual(ink.maxY, CTFontGetAscent(font) + 0.5, "\(sura.suraNumber)")
            XCTAssertGreaterThanOrEqual(ink.minY, -CTFontGetDescent(font) - 0.5, "\(sura.suraNumber)")
        }
    }

    // MARK: Private

    /// Pixels per em when measuring writing lines.
    private static let measuringSize: CGFloat = 256

    /// The plain Arabic text as the system font draws it, at the measuring size.
    private func arabicTextPath(_ text: String) throws -> CGPath {
        let attributed = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: Self.measuringSize),
            NSAttributedString.Key(kCTLanguageAttributeName as String): "ar",
        ])
        let path = CGMutablePath()
        for run in try XCTUnwrap(CTLineGetGlyphRuns(CTLineCreateWithAttributedString(attributed)) as? [CTRun]) {
            let attributes = try XCTUnwrap(CTRunGetAttributes(run) as? [NSAttributedString.Key: Any])
            let font = try XCTUnwrap(attributes[.font] as? UIFont) as CTFont
            let count = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: count), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: count), &positions)
            for (glyph, position) in zip(glyphs, positions) {
                if let glyphPath = CTFontCreatePathForGlyph(font, glyph, nil) {
                    path.addPath(glyphPath, transform: CGAffineTransform(translationX: position.x, y: position.y))
                }
            }
        }
        return path
    }

    /// Where the stroke the letters sit on runs, in em above the baseline: the centre of the densest band of ink
    /// rows just above where the letters' bodies start, so tails below and letters stacked above don't count.
    private func writingLine(of path: CGPath) throws -> CGFloat {
        let em = Self.measuringSize
        let width = Int(path.boundingBoxOfPath.maxX) + 4
        let height = Int(em * 1.4)
        let baseline = Int(em * 0.3)
        var pixels = [UInt8](repeating: 0, count: width * height)
        let context = try XCTUnwrap(CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ))
        context.setFillColor(gray: 1, alpha: 1)
        context.translateBy(x: 2, y: CGFloat(baseline))
        context.addPath(path)
        context.fillPath()

        // Ink per row, from the bottom up.
        var rows = [Int](repeating: 0, count: height)
        pixels.withUnsafeBufferPointer { pixels in
            for row in 0 ..< height {
                var ink = 0
                for x in 0 ..< width {
                    ink += Int(pixels[row * width + x])
                }
                rows[height - 1 - row] = ink
            }
        }
        let densest = try XCTUnwrap(rows.max())
        let bodyBottom = try XCTUnwrap(rows.firstIndex { Double($0) >= 0.35 * Double(densest) })
        let window = bodyBottom ... min(height - 1, bodyBottom + Int(em * 200 / 1024))
        let peak = try XCTUnwrap(window.max { rows[$0] < rows[$1] })
        var bottom = peak
        var top = peak
        while bottom > window.lowerBound, Double(rows[bottom - 1]) >= 0.85 * Double(rows[peak]) {
            bottom -= 1
        }
        while top < window.upperBound, Double(rows[top + 1]) >= 0.85 * Double(rows[peak]) {
            top += 1
        }
        return (CGFloat(bottom + top + 1) / 2 - CGFloat(baseline)) / em
    }

    /// The glyph's advance and ink at 16 pt.
    private func metrics(of character: UInt16) throws -> (advance: CGFloat, ink: CGRect) {
        let font = UIFont(.suraNames, size: 16) as CTFont
        var character = character
        var glyph = CGGlyph()
        XCTAssertTrue(CTFontGetGlyphsForCharacters(font, &character, &glyph, 1))
        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(font, .horizontal, &glyph, &advance, 1)
        let ink = CTFontCreatePathForGlyph(font, glyph, nil)?.boundingBoxOfPath ?? .null
        return (advance.width, ink)
    }
}

/// Each sura's decorated glyph outline, in sura order, from the sura-name font at `size` points.
func suraGlyphInk(at size: CGFloat) throws -> [CGPath] {
    let font = UIFont(.suraNames, size: size) as CTFont
    return try Quran.hafsMadani1405.suras.map { sura in
        var character = try XCTUnwrap(QuranReference.sura(sura).rawValue(locale: Locale(identifier: "ar")).utf16.first)
        var glyph = CGGlyph()
        XCTAssertTrue(CTFontGetGlyphsForCharacters(font, &character, &glyph, 1))
        return try XCTUnwrap(CTFontCreatePathForGlyph(font, glyph, nil))
    }
}

func median(_ values: [CGFloat]) -> CGFloat {
    let sorted = values.sorted()
    return (sorted[(sorted.count - 1) / 2] + sorted[sorted.count / 2]) / 2
}

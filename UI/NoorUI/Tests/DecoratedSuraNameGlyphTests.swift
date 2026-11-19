//
//  DecoratedSuraNameGlyphTests.swift
//

import CoreText
import NoorFont
import QuranKit
import UIKit
import XCTest
@testable import NoorUI

/// `Tools/tighten-sura-name-glyphs.py` makes the decorated sura names sit flush in their boxes, like regular text.
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

    // MARK: Private

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

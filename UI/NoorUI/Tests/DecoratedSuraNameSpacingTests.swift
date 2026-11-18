//
//  DecoratedSuraNameSpacingTests.swift
//

import CoreText
import Localization
import NoorFont
import QuranKit
import QuranLocalization
import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

/// The decorated sura name glyphs sit flush in their boxes, and layout spaces them from the text on their left.
@MainActor
final class DecoratedSuraNameSpacingTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
    }

    func test_decoratedGlyphs_haveNoSideBearings() throws {
        let font = UIFont(.suraNames, size: 16) as CTFont
        for sura in quran.suras {
            var character = try XCTUnwrap(glyph(sura).utf16.first)
            var glyph = CGGlyph()
            XCTAssertTrue(CTFontGetGlyphsForCharacters(font, &character, &glyph, 1))
            var advance = CGSize.zero
            CTFontGetAdvancesForGlyphs(font, .horizontal, &glyph, &advance, 1)
            let ink = try XCTUnwrap(CTFontCreatePathForGlyph(font, glyph, nil)).boundingBoxOfPath

            XCTAssertEqual(ink.minX, 0, accuracy: 0.1, "\(sura.suraNumber) left side bearing")
            XCTAssertEqual(advance.width - ink.maxX, 0, accuracy: 0.1, "\(sura.suraNumber) right side bearing")
        }
    }

    func test_arabicHeaderSuraNames_inkReachesBothEnds() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ImageRenderer needs iOS 16") }
        for page in [quran.pages[381], quran.pages[603]] {
            let ink = try inkColumns(of: "\(suras: page.suras, nameStyle: .decorated)", in: .arabic)

            XCTAssertEqual(ink.firstInk, 0, accuracy: 0.5, "page \(page.pageNumber)")
            XCTAssertEqual(ink.lastInk, ink.width, accuracy: 0.5, "page \(page.pageNumber)")
        }
    }

    func test_englishDecoratedName_spacesTheGlyphFromTheName() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ImageRenderer needs iOS 16") }
        // Ya-Sin's glyph had the narrowest left side bearing, Al-Ankabut's the widest.
        for sura in [quran.suras[35], quran.suras[28]] {
            let name = try inkColumns(of: "\(sura: sura)", in: .english)
            let decorated = try inkColumns(of: "\(sura: sura, nameStyle: .decorated)", in: .english)
            let glyphStart = try XCTUnwrap(decorated.firstInk(after: name.width))

            XCTAssertEqual(glyphStart - name.width, 4 + glyphSpacing, accuracy: 0.75, "\(sura.suraNumber)")
        }
    }

    func test_arabicAyahReference_spacesTheGlyphFromTheCoordinate() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ImageRenderer needs iOS 16") }
        for sura in [quran.suras[35], quran.suras[28]] {
            let glyph = try inkColumns(of: "\(sura: sura)", in: .arabic)
            let coordinate = try inkColumns(of: "\(sura.firstVerse.localizedCoordinate(locale: .arabic))", in: .english)
            let reference = try inkColumns(of: "\(ayah: sura.firstVerse)", in: .arabic)
            let glyphStart = try XCTUnwrap(reference.firstInk(after: reference.width - glyph.width - 0.5))

            XCTAssertEqual(glyphStart - coordinate.width, 4 + glyphSpacing, accuracy: 0.75, "\(sura.suraNumber)")
        }
    }

    func test_arabicSuraNames_spaceTheGlyphOnTheRightFromTheSeparator() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ImageRenderer needs iOS 16") }
        let suras = Array(quran.suras[28 ... 29])
        let right = try inkColumns(of: "\(sura: suras[0])", in: .arabic)
        let left = try inkColumns(of: "\(sura: suras[1])", in: .arabic)
        let separator = try inkColumns(of: MultipartText(stringLiteral: SuraNamesView.separator), in: .arabic)
        let names = try inkColumns(of: "\(suras: suras)", in: .arabic)
        let separatorStart = try XCTUnwrap(names.firstInk(after: left.width))
        let separatorEnd = try XCTUnwrap(names.lastInk(before: names.width - right.width))

        // The left glyph ends its line, so nothing pads it.
        XCTAssertEqual(separatorStart - left.width, separator.firstInk, accuracy: 0.75)
        XCTAssertEqual(
            names.width - right.width - separatorEnd,
            separator.width - separator.lastInk + glyphSpacing,
            accuracy: 0.75
        )
    }

    func test_englishAttributedDecoratedName_spacesTheGlyphFromTheName() throws {
        // The space before the glyph has no font of its own.
        let space = NSAttributedString(string: " ").size().width
        for sura in [quran.suras[35], quran.suras[28]] {
            let name = MultipartText("\(sura: sura)").attributedString(ofSize: .footnote, locale: .english).size().width
            let decorated = try inkColumns(
                of: MultipartText("\(sura: sura, nameStyle: .decorated)").attributedString(ofSize: .footnote, locale: .english)
            )
            let glyphStart = try XCTUnwrap(decorated.firstInk(after: name))

            XCTAssertEqual(glyphStart - name, space + glyphSpacing, accuracy: 0.75, "\(sura.suraNumber)")
        }
    }

    func test_arabicAttributedAyahReference_spacesTheGlyphFromTheCoordinate() throws {
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        let space = NSAttributedString(string: " ", attributes: [.font: font]).size().width
        for sura in [quran.suras[35], quran.suras[28]] {
            let glyph = MultipartText("\(sura: sura)").attributedString(ofSize: .footnote, locale: .arabic).size().width
            let coordinate = NSAttributedString(
                string: sura.firstVerse.localizedCoordinate(locale: .arabic),
                attributes: [.font: font]
            ).size().width
            let reference = try inkColumns(
                of: MultipartText("\(ayah: sura.firstVerse)").attributedString(ofSize: .footnote, locale: .arabic)
            )
            let glyphStart = try XCTUnwrap(reference.firstInk(after: reference.width - glyph - 0.5))

            XCTAssertEqual(glyphStart - coordinate, space + glyphSpacing, accuracy: 0.75, "\(sura.suraNumber)")
        }
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
    private let scale: CGFloat = 3
    /// The space at the footnote size, at the large text size.
    private let glyphSpacing = 16 * MultipartText.FontSize.decoratedGlyphSpacingEm

    private func glyph(_ sura: Sura) -> String {
        QuranReference.sura(sura).rawValue(locale: .arabic)
    }

    @available(iOS 16.0, *)
    private func inkColumns(of text: MultipartText, in locale: Locale) throws -> InkColumns {
        let content = text.view(ofSize: .footnote, allowsWrapping: false)
            .fixedSize()
            .environment(\.locale, locale)
            .environment(\.layoutDirection, locale.isRightToLeft ? .rightToLeft : .leftToRight)
            .dynamicTypeSize(.large)
        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        return try InkColumns(XCTUnwrap(renderer.cgImage), scale: scale)
    }

    private func inkColumns(of text: NSAttributedString) throws -> InkColumns {
        let size = text.size()
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            text.draw(in: CGRect(origin: .zero, size: size))
        }
        return try InkColumns(XCTUnwrap(image.cgImage), scale: scale)
    }
}

/// Which columns of an image have ink, in points.
private struct InkColumns {
    init(_ image: CGImage, scale: CGFloat) throws {
        let width = image.width
        let height = image.height
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
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        columns = (0 ..< width).map { x in
            (0 ..< height).contains { y in pixels[(y * width + x) * 4 + 3] > 64 }
        }
        self.scale = scale
    }

    let columns: [Bool]
    let scale: CGFloat

    var width: CGFloat { CGFloat(columns.count) / scale }
    /// The left edge of the leftmost ink.
    var firstInk: CGFloat { firstInk(after: 0) ?? width }
    /// The right edge of the rightmost ink.
    var lastInk: CGFloat { lastInk(before: width) ?? 0 }

    /// The left edge of the first ink right of `x`.
    func firstInk(after x: CGFloat) -> CGFloat? {
        let start = min(columns.count, Int((x * scale).rounded()))
        return columns[start...].firstIndex(of: true).map { CGFloat($0) / scale }
    }

    /// The right edge of the last ink left of `x`.
    func lastInk(before x: CGFloat) -> CGFloat? {
        let end = max(0, min(columns.count, Int((x * scale).rounded())))
        return columns[..<end].lastIndex(of: true).map { CGFloat($0 + 1) / scale }
    }
}

private extension Locale {
    static let english = Locale(identifier: "en")
    static let arabic = Locale(identifier: "ar")
}

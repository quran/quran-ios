//
//  ThemedColorInvertTests.swift
//

import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class ThemedColorInvertTests: XCTestCase {
    func test_lightPage_keepsBlackInk() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ImageRenderer needs iOS 16") }
        let ink = try renderedInk(.paper, colorScheme: .light, themeColorScheme: .light)
        assertEqual(ink, pixel(of: .black))
    }

    func test_quietPage_tintsInkWithTheAppearanceTextColor() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ImageRenderer needs iOS 16") }
        for scheme in [ColorScheme.light, .dark] {
            let ink = try renderedInk(.quiet, colorScheme: .dark, themeColorScheme: scheme)
            let text = ThemeStyle.quiet.textColor.resolvedColor(with: scheme.traitCollection)
            assertEqual(ink, pixel(of: text), "\(scheme)")
        }
    }

    // MARK: Private

    @available(iOS 16.0, *)
    private func renderedInk(_ style: ThemeStyle, colorScheme: ColorScheme, themeColorScheme: ColorScheme) throws -> [Int] {
        let blackImage = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        let renderer = ImageRenderer(content: QuranThemedImage(image: blackImage)
            .frame(width: 4, height: 4)
            .environment(\.themeStyle, style)
            .environment(\.colorScheme, colorScheme)
            .environment(\.themeColorSchemeOverride, themeColorScheme))
        let image = try XCTUnwrap(renderer.cgImage)
        return pixel { $0.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1)) }
    }

    private func pixel(of color: UIColor) -> [Int] {
        pixel { context in
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    /// Draws into one sRGB pixel, so rendered and expected colors go through the same conversion.
    private func pixel(_ draw: (CGContext) -> Void) -> [Int] {
        var data = [UInt8](repeating: 0, count: 4)
        data.withUnsafeMutableBytes { bytes in
            let context = CGContext(
                data: bytes.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            draw(context)
        }
        return data.prefix(3).map(Int.init)
    }

    private func assertEqual(_ actual: [Int], _ expected: [Int], _ message: String = "", line: UInt = #line) {
        let close = zip(actual, expected).allSatisfy { abs($0 - $1) <= 3 }
        XCTAssertTrue(close, "\(actual) is not \(expected) \(message)", line: line)
    }
}

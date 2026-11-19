//
//  ThemedColorInvertTests.swift
//

import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class ThemedColorInvertTests: XCTestCase {
    func test_originalLightPage_keepsBlackInk() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ImageRenderer needs iOS 16") }
        let ink = try rendered(.black, .original, colorScheme: .light)
        assertEqual(ink, pixel(of: .black))
    }

    func test_quietPage_tintsInkWithTheAppearanceTextColor() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ImageRenderer needs iOS 16") }
        for scheme in [ColorScheme.light, .dark] {
            let ink = try rendered(.black, .quiet, colorScheme: .dark, themeColorScheme: scheme)
            assertEqual(ink, pixel(of: textColor(.quiet, scheme)), "\(scheme)")
        }
    }

    func test_calmLightPage_tintsBlackInkAndKeepsColors() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Light pages are tinted from iOS 17") }
        let ink = try rendered(.black, .calm, colorScheme: .light)
        assertEqual(ink, [0x32, 0x28, 0x1E])

        let green = UIColor(sRGB: 0x04943C)
        let color = try rendered(green, .calm, colorScheme: .light)
        assertEqual(color, pixel(of: green))
    }

    func test_darkPage_keepsHueOfColors() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("The ink shader needs iOS 17") }
        // Inverting #04943C and rotating its hue back gives #25B55D, which the text color multiplies.
        let text = textColor(.calm, .dark)
        let color = try rendered(UIColor(sRGB: 0x04943C), .calm, colorScheme: .dark)
        assertEqual(color, pixel(of: UIColor(sRGB: 0x25B55D).multiplied(by: text)))
    }

    func test_darkPage_clampsBrightColorsAfterTheTextColor() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("The ink shader needs iOS 17") }
        // #E01020 inverts and rotates back to red 1.396, past white, as SwiftUI's folded filters keep it.
        let text = textColor(.quiet, .dark)
        let color = try rendered(UIColor(sRGB: 0xE01020), .quiet, colorScheme: .dark)
        let rotated = UIColor(red: 1.396, green: 0.581, blue: 0.643, alpha: 1)
        assertEqual(color, pixel(of: rotated.multiplied(by: text)))
    }

    // MARK: Private

    @available(iOS 16.0, *)
    private func rendered(
        _ color: UIColor,
        _ style: ThemeStyle,
        colorScheme: ColorScheme,
        themeColorScheme: ColorScheme? = nil
    ) throws -> [Int] {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        let renderer = ImageRenderer(content: QuranThemedImage(image: image)
            .frame(width: 4, height: 4)
            .environment(\.themeStyle, style)
            .environment(\.colorScheme, colorScheme)
            .environment(\.themeColorSchemeOverride, themeColorScheme ?? colorScheme))
        let cgImage = try XCTUnwrap(renderer.cgImage)
        return pixel { $0.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1)) }
    }

    private func textColor(_ style: ThemeStyle, _ scheme: ColorScheme) -> UIColor {
        style.textColor.resolvedColor(with: scheme.traitCollection)
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

private extension UIColor {
    convenience init(sRGB hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    /// Multiplies sRGB components, as `colorMultiply` does.
    func multiplied(by other: UIColor) -> UIColor {
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 * r2, green: g1 * g2, blue: b1 * b2, alpha: 1)
    }
}

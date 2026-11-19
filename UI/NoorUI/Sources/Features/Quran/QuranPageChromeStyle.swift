//
//  QuranPageChromeStyle.swift
//

import QuranKit
import SwiftUI
import UIKit
import UIx

/// The colors of the sura headers and ayah markers the app draws on Quran pages.
public enum QuranPageChromeStyle {
    case green
    case blue
    case bronze

    // MARK: Lifecycle

    public init(reading: Reading) {
        switch reading {
        case .hafs_1439:
            self = .blue
        case .hafs_1421:
            self = .bronze
        case .hafs_1405, .hafs_1440, .hafs_1441, .tajweed, .indoPak:
            self = .green
        }
    }

    // MARK: Public

    /// The palette for a Quran page in `pageColorScheme`. Inverted (dark) pages cap every chrome
    /// color at the brightness of the page `text`, so chrome never outshines the ink.
    public func palette(for pageColorScheme: ColorScheme, text: Color) -> QuranPageChromePalette {
        let palette = palette(for: pageColorScheme)
        return pageColorScheme == .dark ? palette.capped(atLuminanceOf: UIColor(text)) : palette
    }

    /// Dark palettes have no marker fill, so the ring and digits sit straight on the inverted page.
    public func palette(for colorScheme: ColorScheme) -> QuranPageChromePalette {
        switch (self, colorScheme) {
        case (.blue, .dark):
            QuranPageChromePalette(header: 0x73AFFA, markerRing: 0x73AFFA, markerFill: nil, markerText: 0x73AFFA)
        case (.blue, _):
            QuranPageChromePalette(header: 0x2563EB, markerRing: 0x2563EB, markerFill: 0xEFF6FF, markerText: 0x1D4ED8)
        case (.green, .dark):
            QuranPageChromePalette(header: 0x10B981, markerRing: 0x10B981, markerFill: nil, markerText: 0x34D399)
        case (.green, _):
            QuranPageChromePalette(header: 0x047857, markerRing: 0x047857, markerFill: 0xECFDF5, markerText: 0x047857)
        case (.bronze, .dark):
            QuranPageChromePalette(header: 0xD6A85C, markerRing: 0xD6A85C, markerFill: nil, markerText: 0xEBC98A)
        case (.bronze, _):
            QuranPageChromePalette(header: 0x8B5E1A, markerRing: 0x8B5E1A, markerFill: 0xFBF3E4, markerText: 0x7A5214)
        }
    }
}

public struct QuranPageChromePalette {
    // MARK: Lifecycle

    init(header: Int, markerRing: Int, markerFill: Int?, markerText: Int) {
        self.init(
            header: UIColor(rgb: header),
            markerRing: UIColor(rgb: markerRing),
            markerFill: markerFill.map(UIColor.init(rgb:)) ?? .clear,
            markerText: UIColor(rgb: markerText)
        )
    }

    private init(header: UIColor, markerRing: UIColor, markerFill: UIColor, markerText: UIColor) {
        headerColor = header
        markerRingColor = markerRing
        markerFillColor = markerFill
        markerTextColor = markerText
    }

    // MARK: Public

    public var header: Color { Color(uiColor: headerColor) }
    public var markerRing: Color { Color(uiColor: markerRingColor) }
    public var markerFill: Color { Color(uiColor: markerFillColor) }
    public var markerText: Color { Color(uiColor: markerTextColor) }

    // MARK: Internal

    func capped(atLuminanceOf text: UIColor) -> QuranPageChromePalette {
        QuranPageChromePalette(
            header: headerColor.capped(atLuminanceOf: text),
            markerRing: markerRingColor.capped(atLuminanceOf: text),
            markerFill: markerFillColor,
            markerText: markerTextColor.capped(atLuminanceOf: text)
        )
    }

    // MARK: Private

    private let headerColor: UIColor
    private let markerRingColor: UIColor
    private let markerFillColor: UIColor
    private let markerTextColor: UIColor
}

extension UIColor {
    /// WCAG relative luminance, from extended sRGB components.
    var relativeLuminance: CGFloat {
        let (r, g, b, _) = linearComponents
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Darkens a color brighter than `reference` until their relative luminances match, scaling
    /// linear-light RGB so hue and saturation are kept. Colors at or below it are returned unchanged.
    func capped(atLuminanceOf reference: UIColor) -> UIColor {
        let luminance = relativeLuminance
        let limit = reference.relativeLuminance
        guard luminance > limit else {
            return self
        }
        let scale = limit / luminance
        let (r, g, b, a) = linearComponents
        return UIColor(red: Self.encode(r * scale), green: Self.encode(g * scale), blue: Self.encode(b * scale), alpha: a)
    }

    private var linearComponents: (CGFloat, CGFloat, CGFloat, CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        // Extended sRGB, so Display P3 theme colors keep their exact value.
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Self.decode(r), Self.decode(g), Self.decode(b), a)
    }

    private static func decode(_ c: CGFloat) -> CGFloat {
        let v = abs(c)
        let linear = v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        return c < 0 ? -linear : linear
    }

    private static func encode(_ c: CGFloat) -> CGFloat {
        let v = abs(c)
        let encoded = v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1 / 2.4) - 0.055
        return c < 0 ? -encoded : encoded
    }
}

//
//  ThemedColorInvert.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-12-05.
//

import SwiftUI
import UIKit

private struct ThemedColorInvertModifier: ViewModifier {
    // MARK: Internal

    @Environment(\.quranPageColorScheme) var quranPageColorScheme
    @Environment(\.themeColors) var themeColors

    func body(content: Content) -> some View {
        let text = textComponents
        let isDark = quranPageColorScheme == .dark
        if !isDark && text.isBlack {
            content
        } else if #available(iOS 17.0, *) {
            // One pass for both page schemes, see QuranPageInk.metal.
            content.colorEffect(
                ShaderLibrary.bundle(.module).quranPageInk(
                    .float4(text.red, text.green, text.blue, 1),
                    .float(isDark ? 1 : 0)
                )
            )
        } else if isDark {
            // Rotating the hue back keeps colored chrome and tajweed colors meaningful, and the
            // multiply turns the white ink into the theme's text color.
            content
                .colorInvert()
                .hueRotation(.degrees(180))
                .colorMultiply(themeColors.text)
        } else {
            // Light pages keep black ink before iOS 17.
            content
        }
    }

    // MARK: Private

    /// The theme text color as sRGB components. The theme colors are Display P3 assets.
    private var textComponents: InkColor {
        let color = themeColors.style.textColor.resolvedColor(with: themeColors.colorScheme.traitCollection)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return InkColor(red: Float(red), green: Float(green), blue: Float(blue))
    }
}

private struct InkColor {
    let red: Float
    let green: Float
    let blue: Float

    /// Within half a step of 8-bit black, where tinting light pages would change nothing.
    var isBlack: Bool {
        max(red, green, blue) < 0.5 / 255
    }
}

extension View {
    /// Colors Quran page ink with the theme's text color.
    public func invertThemedColorIfNeeded() -> some View {
        modifier(ThemedColorInvertModifier())
    }
}

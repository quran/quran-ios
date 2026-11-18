//
//  ThemedColorInvert.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-12-05.
//

import SwiftUI

private struct ThemedColorInvertModifier: ViewModifier {
    @Environment(\.quranPageColorScheme) var quranPageColorScheme
    @Environment(\.themeColors) var themeColors

    func body(content: Content) -> some View {
        if quranPageColorScheme == .dark {
            // Rotating the hue back keeps colored chrome and tajweed colors meaningful, and the
            // multiply turns the white ink into the theme's text color.
            content
                .colorInvert()
                .hueRotation(.degrees(180))
                .colorMultiply(themeColors.text)
        } else {
            content
        }
    }
}

extension View {
    public func invertThemedColorIfNeeded() -> some View {
        modifier(ThemedColorInvertModifier())
    }
}

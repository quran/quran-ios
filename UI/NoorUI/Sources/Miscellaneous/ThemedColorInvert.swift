//
//  ThemedColorInvert.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-12-05.
//

import SwiftUI

private struct ThemedColorInvertModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.themeStyle) var themeStyle

    func body(content: Content) -> some View {
        if colorScheme == .dark || themeStyle == .quiet {
            // Rotating the hue back keeps colored chrome and tajweed colors meaningful.
            content
                .colorInvert()
                .hueRotation(.degrees(180))
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

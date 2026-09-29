//
//  AppIconAccent.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import UIKit
import UIx

/// The colors an app icon lends the interface.
public struct AppIconAccent: Sendable {
    // MARK: Lifecycle

    /// - Parameters:
    ///   - light: The accent in light appearance.
    ///   - dark: The accent in dark appearance.
    ///   - onLight: Text and glyphs drawn on a filled accent background in light appearance.
    ///   - onDark: Text and glyphs drawn on a filled accent background in dark appearance.
    public init(light: UIColor, dark: UIColor, onLight: UIColor = .white, onDark: UIColor) {
        self.init(
            color: UIColor(light: light, dark: dark),
            onColor: UIColor(light: onLight, dark: onDark)
        )
    }

    init(color: UIColor, onColor: UIColor) {
        self.color = color
        self.onColor = onColor
    }

    // MARK: Internal

    /// The accent, resolved per light and dark appearance.
    let color: UIColor

    /// Text and glyphs drawn on a filled `color` background.
    let onColor: UIColor
}

extension AppIconAccent {
    // MARK: Internal

    /// The accent windows use as their tint, which SwiftUI reads as `accentColor`.
    @MainActor static var current: AppIconAccent {
        currentAccent ?? standard
    }

    @MainActor
    static func setCurrent(_ accent: AppIconAccent?) {
        currentAccent = accent
    }

    // MARK: Private

    /// A neutral amber, matching the QuranEngine icons. It shows only until the app
    /// applies the accent of its icon, such as in previews and tests.
    private static let standard = AppIconAccent(
        light: UIColor(rgb: 0x874C00),
        dark: UIColor(rgb: 0xF5B454),
        onDark: UIColor(rgb: 0x3A2200)
    )

    @MainActor private static var currentAccent: AppIconAccent?
}

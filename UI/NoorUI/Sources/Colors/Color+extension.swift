//
//  Color+extension.swift
//
//
//  Created by Afifi, Mohamed on 7/23/21.
//

import SwiftUI
import UIx

extension Color {
    /// Text and glyphs drawn on a filled `accentColor` background.
    @MainActor public static var onAccent: Color {
        Color(UIColor.onAccent)
    }

    public static var pageMarkerTint: Color {
        Color(UIColor(light: UIColor(rgb: 0x004D40), dark: UIColor(rgb: 0x039F85)))
    }

    /// Highlights the recited verse and word. It stays the same whatever the app icon.
    static var recitation: Color {
        Color(UIColor.recitation)
    }
}

public extension UIColor {
    /// Text and glyphs drawn on a filled accent background.
    @MainActor static var onAccent: UIColor {
        AppIconAccent.current.onColor
    }
}

extension UIColor {
    static var recitation: UIColor {
        UIColor(light: UIColor(rgb: 0xDC7702), dark: UIColor(rgb: 0xEF911D))
    }

    static var themeCalmText: UIColor {
        UIColor(named: "theme-calm-text", in: .module, compatibleWith: nil)!
    }

    static var themeCalmBackground: UIColor {
        UIColor(named: "theme-calm-bg", in: .module, compatibleWith: nil)!
    }

    static var themeFocusText: UIColor {
        UIColor(named: "theme-focus-text", in: .module, compatibleWith: nil)!
    }

    static var themeFocusBackground: UIColor {
        UIColor(named: "theme-focus-bg", in: .module, compatibleWith: nil)!
    }

    static var themeOriginalText: UIColor {
        UIColor(named: "theme-original-text", in: .module, compatibleWith: nil)!
    }

    static var themeOriginalBackground: UIColor {
        UIColor(named: "theme-original-bg", in: .module, compatibleWith: nil)!
    }

    static var themePaperText: UIColor {
        UIColor(named: "theme-paper-text", in: .module, compatibleWith: nil)!
    }

    static var themePaperBackground: UIColor {
        UIColor(named: "theme-paper-bg", in: .module, compatibleWith: nil)!
    }

    static var themeQuietText: UIColor {
        UIColor(named: "theme-quiet-text", in: .module, compatibleWith: nil)!
    }

    static var themeQuietBackground: UIColor {
        UIColor(named: "theme-quiet-bg", in: .module, compatibleWith: nil)!
    }
}

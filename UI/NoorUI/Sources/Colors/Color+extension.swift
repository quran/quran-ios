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

    /// Highlights the word being recited inside its `recitation`-tinted verse. Teal against
    /// that orange, so the moving word reads as separate from the verse around it. It stays
    /// the same whatever the app icon, like `recitation`.
    static var recitedWord: Color {
        Color(UIColor.recitedWord)
    }
}

public extension UIColor {
    /// Text and glyphs drawn on a filled accent background.
    @MainActor static var onAccent: UIColor {
        AppIconAccent.current.onColor
    }

    /// Background for the popover naming the word being recited. Neutral, so it competes
    /// with neither the ayah highlight nor the word highlight drawn under it. Fixed rather
    /// than dynamic, because the popover draws a light label in both appearances.
    static var recitedWordPopoverBackground: UIColor {
        UIColor(red: 38 / 255, green: 38 / 255, blue: 40 / 255, alpha: 1)
    }
}

extension UIColor {
    static var recitation: UIColor {
        UIColor(light: UIColor(rgb: 0xDC7702), dark: UIColor(rgb: 0xEF911D))
    }

    static var recitedWord: UIColor {
        UIColor(light: UIColor(rgb: 0x1B6B71), dark: UIColor(rgb: 0x2FA4AC))
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

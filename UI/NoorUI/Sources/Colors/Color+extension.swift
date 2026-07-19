//
//  Color+extension.swift
//
//
//  Created by Afifi, Mohamed on 7/23/21.
//

import SwiftUI

extension Color {
    public static var appIdentity: Color {
        Color("appTint", bundle: .module)
    }

    public static var pageMarkerTint: Color {
        Color(UIColor { collection in
            collection.userInterfaceStyle == .dark ? UIColor(rgb: 0x039F85) : UIColor(rgb: 0x004D40)
        })
    }
}

public extension UIColor {
    static var appIdentity: UIColor {
        UIColor(named: "appTint", in: .module, compatibleWith: nil) ?? .systemIndigo
    }
}

extension UIColor {
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

//
//  FontName.swift
//
//
//  Created by Mohamed Afifi on 2023-06-23.
//

import Foundation
import SwiftUI

public enum FontName: CaseIterable {
    /// Used in Arabic tafseer
    case arabic

    /// Used in Amharic translation
    case amharic

    /// Used in quran text in translation view
    case quran

    /// Used in arabic suras in Uthmanic font
    case suraNames

    struct FontDetails {
        let name: String
        let family: String
        let fileName: String
    }

    // MARK: Internal

    var details: FontDetails {
        switch self {
        case .arabic:
            return FontDetails(
                name: "Kitab-Regular",
                family: "Kitab",
                fileName: "Kitab-Regular.ttf"
            )
        case .amharic:
            return FontDetails(
                name: "AbyssinicaSIL",
                family: "Abyssinica SIL",
                fileName: "AbyssinicaSIL-R.ttf"
            )
        case .quran:
            return FontDetails(
                name: "KFGQPCHAFSUthmanicScript-Regula",
                family: "KFGQPC HAFS Uthmanic Script",
                fileName: "uthmanic_hafs_ver12.otf"
            )
        case .suraNames:
            return FontDetails(
                name: "icomoon",
                family: "icomoon",
                fileName: "surah_names.ttf"
            )
        }
    }
}

private let arabicQuranTextFontSize: CGFloat = 24
private let arabicTranslationTextFontSize: CGFloat = 24
private let englishTranslationTextFontSize: CGFloat = 20
private let amharicTranslationTextFontSize: CGFloat = 20

public extension Font {
    static func custom(_ name: FontName, size: CGFloat) -> Font {
        custom(name.details.name, size: size)
    }

    static func custom(_ name: FontName, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        custom(name.details.name, size: size, relativeTo: textStyle)
    }
}

public extension UIFont {
    convenience init(_ font: FontName, size: CGFloat) {
        self.init(name: font.details.name, size: size)!
    }
}

extension FontName {
    public static func registerFonts() {
        for font in FontName.allCases {
            registerFont(font.details.fileName, in: .module)
        }
    }

    private static func registerFont(_ name: String, in bundle: Bundle) {
        let fontURL = bundle.url(forResource: name, withExtension: nil)!
        let fontDataProvider = CGDataProvider(url: fontURL as CFURL)!
        let font = CGFont(fontDataProvider)!
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            var message = "Couldn't register font \(name)."
            if let error {
                message += " Error: \(dump(error))"
            }
            fatalError(message)
        }
    }
}

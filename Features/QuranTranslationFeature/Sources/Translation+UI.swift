//
//  Translation+UI.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/29/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import NoorUI
import QuranText
import SwiftUI

extension Translation {
    /// Scripts the system font cannot render need their own bundled font. Everything
    /// else stays on the system font, which adapts to the reader's Dynamic Type.
    ///
    /// `fontSize` is the size the caller sets on the environment. Only the Dhivehi
    /// font needs it: it carries a cascade list, which requires a `UIFont`, and
    /// SwiftUI will not scale those. The others scale from the environment as usual.
    func textFont(for fontSize: FontSize) -> Font {
        switch primaryLanguage {
        case "ar": .arabicTafseer()
        case "dv": .dhivehi(dynamicTypeSize: fontSize.dynamicTypeSize)
        default: .body
        }
    }

    var characterDirection: Locale.LanguageDirection {
        Locale.characterDirection(forLanguage: languageCode)
    }

    /// `languageCode` comes from the translations endpoint, which sends bare ISO
    /// codes today. Match on the primary subtag so a region or casing change
    /// upstream cannot silently drop the translation back to the system font.
    private var primaryLanguage: String {
        languageCode
            .lowercased()
            .split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? ""
    }
}

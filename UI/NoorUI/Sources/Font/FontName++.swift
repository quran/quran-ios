//
//  FontName++.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/30/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import NoorFont
import SwiftUI
import UIKit

private let arabicTafseerTextFontSize: CGFloat = 21
private let dhivehiTextFontSize: CGFloat = 21

public extension Font {
    static func arabicTafseer() -> Font {
        custom(.arabic, size: arabicTafseerTextFontSize)
    }

    /// Faruma covers Thaana but almost no Arabic, so Arabic quotations inside a
    /// Dhivehi translation fall back to the system Arabic font. That font applies
    /// the الله ligature unconditionally, stacking the text's own shadda on top of
    /// the one already drawn into the ligature glyph. Kitab makes that ligature
    /// contextual, so cascading to it keeps vocalised Arabic correct without
    /// altering the translation text.
    ///
    /// A cascade needs a `UIFont`, and SwiftUI does not apply Dynamic Type to a
    /// `Font` built from one. The caller therefore passes the size it is about to
    /// set on the environment, and the font is scaled to it up front.
    static func dhivehi(dynamicTypeSize: DynamicTypeSize) -> Font {
        Font(UIFont.dhivehi(size: dhivehiTextFontSize, dynamicTypeSize: dynamicTypeSize))
    }
}

extension UIFont {
    /// Faruma for Thaana, falling back to Kitab for Arabic. The two do not overlap
    /// — Kitab has no Thaana glyphs — so the cascade order is unambiguous.
    static func dhivehi(size: CGFloat, dynamicTypeSize: DynamicTypeSize) -> UIFont {
        let thaana = UIFont(.dhivehi, size: size)
        let arabic = UIFont(.arabic, size: size)
        let descriptor = thaana.fontDescriptor.addingAttributes([
            .cascadeList: [arabic.fontDescriptor],
        ])
        return UIFontMetrics(forTextStyle: .body).scaledFont(
            for: UIFont(descriptor: descriptor, size: size),
            compatibleWith: UITraitCollection(preferredContentSizeCategory: dynamicTypeSize.contentSizeCategory)
        )
    }
}

private extension DynamicTypeSize {
    var contentSizeCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
    }
}

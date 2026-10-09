//
//  QuranTranslationSpacing.swift
//
//
//  Created by Mohamed Afifi on 2026-10-09.
//

import CoreGraphics

/// Vertical rhythm of translation mode, at the default Dynamic Type size.
enum QuranTranslationSpacing {
    /// From the verse separator, or the sura or page header, to a verse's first content.
    static let verseTop: CGFloat = 14
    /// Between one translation and the next, and from the Arabic text to the first translation.
    static let translationTop: CGFloat = 16
    /// From a verse's last content to its separator.
    static let separatorTop: CGFloat = 16
    /// From a translation's last line to its translator name.
    static let translatorNameTop: CGFloat = 2
}

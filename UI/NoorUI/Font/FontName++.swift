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
import QuranText
import SwiftUI

private let arabicQuranTextFontSize: CGFloat = 24
private let arabicTranslationTextFontSize: CGFloat = 24
private let englishTranslationTextFontSize: CGFloat = 20
private let amharicTranslationTextFontSize: CGFloat = 20

public extension Font {
    static func quran(ofSize size: FontSize) -> Font {
        custom(.quran, size: size.fontSize(forMediumSize: arabicQuranTextFontSize))
    }
}

public extension UIFont {
    // MARK: Translator

    static func translatorNameArabic(ofSize size: FontSize) -> UIFont {
        UIFont(.arabic, size: size.fontSize(forMediumSize: 20))
    }

    static func translatorNameEnglish(ofSize size: FontSize) -> UIFont {
        .systemFont(ofSize: size.fontSize(forMediumSize: 17))
    }

    static func translatorNameAmharic(ofSize size: FontSize) -> UIFont {
        UIFont(.amharic, size: size.fontSize(forMediumSize: 17))
    }

    // MARK: Quran

    static func arabicQuranText(ofSize size: FontSize) -> UIFont {
        UIFont(.quran, size: size.fontSize(forMediumSize: arabicQuranTextFontSize))
    }

    // MARK: Translations

    static func arabicTranslation(ofSize size: FontSize, factor: CGFloat) -> UIFont {
        UIFont(.arabic, size: size.fontSize(forMediumSize: arabicTranslationTextFontSize) * factor)
    }

    static func englishTranslation(ofSize size: FontSize, factor: CGFloat) -> UIFont {
        .systemFont(ofSize: size.fontSize(forMediumSize: englishTranslationTextFontSize) * factor)
    }

    static func amharicTranslation(ofSize size: FontSize, factor: CGFloat) -> UIFont {
        UIFont(.amharic, size: size.fontSize(forMediumSize: amharicTranslationTextFontSize) * factor)
    }
}

public func attributedString(of text: String, arabicSuraName: String, fontSize: CGFloat) -> NSAttributedString {
    let systemFont = UIFont.systemFont(ofSize: fontSize)
    let text = NSMutableAttributedString(string: text, attributes: [.font: systemFont])
    if NSLocale.preferredLanguages.first == "ar" {
        return text
    }
    text.append(NSAttributedString(string: " "))
    let decoratedFont = UIFont(.suraNames, size: fontSize + 4)
    text.append(NSAttributedString(string: arabicSuraName, attributes: [.font: decoratedFont]))
    return text
}

//
//  UIFont+Theme.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/30/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import UIKit

private enum Font: String {
    case arabic = "KFGQPCUthmanTahaNaskh"          // family: KFGQPC Uthman Taha Naskh
    case amharic = "AbyssinicaSIL"                 // family: Abyssinica SIL
    case quran = "KFGQPCHAFSUthmanicScript-Regula" // family: KFGQPC HAFS Uthmanic Script
}

private let arabicQuranTextFontSize: CGFloat = 24
private let arabicTranslationTextFontSize: CGFloat = 24
private let englishTranslationTextFontSize: CGFloat = 20
private let amharicTranslationTextFontSize: CGFloat = 20

extension UIFont {

    private convenience init(_ font: Font, size: CGFloat) {
        self.init(name: font.rawValue, size: size)! //swiftlint:disable:this force_unwrapping
    }

    // Translator

    static func translatorNameArabic(ofSize size: FontSize) -> UIFont {
        return UIFont(.arabic, size: size.fontSize(forMediumSize: 20))
    }
    static func translatorNameEnglish(ofSize size: FontSize) -> UIFont {
        return .systemFont(ofSize: size.fontSize(forMediumSize: 17))
    }
    static func translatorNameAmharic(ofSize size: FontSize) -> UIFont {
        return UIFont(.amharic, size: size.fontSize(forMediumSize: 17))
    }

    // Quran

    static func arabicQuranText(ofSize size: FontSize) -> UIFont {
        return UIFont(.quran, size: size.fontSize(forMediumSize: arabicQuranTextFontSize))
    }

    // Translations

    static func arabicTranslation(ofSize size: FontSize) -> UIFont {
        return UIFont(.arabic, size: size.fontSize(forMediumSize: arabicTranslationTextFontSize))
    }

    static func englishTranslation(ofSize size: FontSize) -> UIFont {
        return .systemFont(ofSize: size.fontSize(forMediumSize: englishTranslationTextFontSize))
    }

    static func amharicTranslation(ofSize size: FontSize) -> UIFont {
        return UIFont(.amharic, size: size.fontSize(forMediumSize: amharicTranslationTextFontSize))
    }
}

extension Translation {

    func preferredTextFont(ofSize size: FontSize) -> UIFont {
        if languageCode == "am" {
            return .amharicTranslation(ofSize: size)
        } else if languageCode == "ar" {
            return .arabicTranslation(ofSize: size)
        } else {
            return .englishTranslation(ofSize: size)
        }
    }

    func preferredTranslatorNameFont(ofSize size: FontSize) -> UIFont {
        if languageCode == "am" {
            return .translatorNameAmharic(ofSize: size)
        } else if languageCode == "ar" {
            return .translatorNameArabic(ofSize: size)
        } else {
            return .translatorNameEnglish(ofSize: size)
        }
    }

    var characterDirection: Locale.LanguageDirection {
        return Locale.characterDirection(forLanguage: languageCode)
    }
}

extension TranslationText {
    func attributedText(withFontSize size: FontSize) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        if translation.characterDirection == .rightToLeft {
            style.alignment = .right
        } else {
            style.alignment = .left
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font            : translation.preferredTextFont(ofSize: size),
            .paragraphStyle  : style]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        return attributedString
    }
}

private extension FontSize {
    func fontSize(forMediumSize size: CGFloat) -> CGFloat {
        let factor: CGFloat
        switch self {
        case .xSmall: factor = 0.7 * 0.7
        case .small:  factor = 0.7
        case .medium: factor = 1
        case .large:  factor = 1 / 0.8
        case .xLarge: factor = 1 / 0.8 / 0.8
        }
        return size * factor
    }
}

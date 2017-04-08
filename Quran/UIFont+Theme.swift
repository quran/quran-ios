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

private let amharic = "AbyssinicaSIL"
private let arabic  = "KFGQPCUthmanTahaNaskh"

extension UIFont {

    // swiftlint:disable force_unwrapping
    static let translationTranslatorNameArabic: UIFont = UIFont(name: arabic, size: 20)!
    static let translationTranslatorNameEnglish: UIFont = .systemFont(ofSize: 17)
    static let translationTranslatorNameAmharic: UIFont = UIFont(name: amharic, size: 17)!

    static let translationArabicQuranText: UIFont = UIFont(name: arabic, size: 24)!

    static let translationArabicTranslation: UIFont = UIFont(name: arabic, size: 20)!
    static let translationEnglishTranslation: UIFont = .systemFont(ofSize: 20)
    static let translationAmharicTranslation: UIFont = UIFont(name: amharic, size: 22)!
    // swiftlint:enable force_unwrapping
}

extension Translation {

    var preferredTextFont: UIFont {
        if languageCode == "am" {
            return .translationAmharicTranslation
        } else if languageCode == "ar" {
            return .translationArabicTranslation
        } else {
            return .translationEnglishTranslation
        }
    }

    var preferredTranslatorNameFont: UIFont {
        if languageCode == "am" {
            return .translationTranslatorNameAmharic
        } else if languageCode == "ar" {
            return .translationTranslatorNameArabic
        } else {
            return .translationTranslatorNameEnglish
        }
    }

    var characterDirection: Locale.LanguageDirection {
        return Locale.characterDirection(forLanguage: languageCode)
    }
}

extension TranslationText {
    var attributedText: NSAttributedString {
        let style = NSMutableParagraphStyle()
        if translation.characterDirection == .rightToLeft {
            style.alignment = .right
        } else {
            style.alignment = .left
        }

        let attributes = [
            NSFontAttributeName            : translation.preferredTextFont,
            NSForegroundColorAttributeName : UIColor.translationText,
            NSParagraphStyleAttributeName  : style]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        return attributedString
    }
}

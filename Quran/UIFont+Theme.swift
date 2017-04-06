//
//  UIFont+Theme.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/30/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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

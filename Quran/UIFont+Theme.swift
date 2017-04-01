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

    static let translationArabicQuranText: UIFont = UIFont(name: arabic, size: 20)!

    static let translationArabicTranslation: UIFont = UIFont(name: arabic, size: 17)!
    static let translationEnglishTranslation: UIFont = .systemFont(ofSize: 17)
    static let translationAmharicTranslation: UIFont = UIFont(name: amharic, size: 17)!
    // swiftlint:enable force_unwrapping
}

extension Translation {

    var preferredTextFont: UIFont {
        let displayName = self.displayName.lowercased()
        if displayName.contains("amharic") {
            return .translationAmharicTranslation
        } else if displayName.contains("arabic") {
            return .translationArabicTranslation
        } else {
            return .translationEnglishTranslation
        }
    }

    var preferredTranslatorNameFont: UIFont {
        let displayName = self.displayName.lowercased()
        if displayName.contains("amharic") {
            return .translationTranslatorNameAmharic
        } else if displayName.contains("arabic") {
            return .translationTranslatorNameArabic
        } else {
            return .translationTranslatorNameEnglish
        }
    }
}

extension TranslationText {
    var attributedText: NSAttributedString {
        let attributes = [
            NSFontAttributeName            : translation.preferredTextFont,
            NSForegroundColorAttributeName : UIColor.translationText]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        return attributedString
    }
}

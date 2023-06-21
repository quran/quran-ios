//
//  Translation+UI.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/29/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import NoorUI
import QuranText
import UIKit

extension Translation {
    func preferredTextFont(ofSize size: FontSize, factor: CGFloat = 1) -> UIFont {
        if languageCode == "am" {
            return .amharicTranslation(ofSize: size, factor: factor)
        } else if languageCode == "ar" {
            return .arabicTranslation(ofSize: size, factor: factor)
        } else {
            return .englishTranslation(ofSize: size, factor: factor)
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
        Locale.characterDirection(forLanguage: languageCode)
    }
}

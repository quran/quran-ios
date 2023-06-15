//
//  FontName.swift
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

import QuranText
import SwiftUI

// swiftformat:disable consecutiveSpaces

public enum FontName: String {
    // used to show Arabic tafseer
    case arabic = "Kitab-Regular"                   // family: Kitab                        file: Kitab-Regular.ttf
    // used to show Amharic translation
    case amharic = "AbyssinicaSIL"                  // family: Abyssinica SIL               file: AbyssinicaSIL-R.ttf
    // used to show quran text in translation view
    case quran = "KFGQPCHAFSUthmanicScript-Regula"  // family: KFGQPC HAFS Uthmanic Script  file: uthmanic_hafs_ver12.otf
    // used to show arabic suras in Uthmanic font
    case suraNames = "icomoon"                      // family: icomoon                      file: surah_names.ttf
}

// swiftformat:enable consecutiveSpaces

private let arabicQuranTextFontSize: CGFloat = 24
private let arabicTranslationTextFontSize: CGFloat = 24
private let englishTranslationTextFontSize: CGFloat = 20
private let amharicTranslationTextFontSize: CGFloat = 20

@available(iOS 13.0, *)
public extension Font {
    static func custom(_ name: FontName, size: CGFloat) -> Font {
        custom(name.rawValue, size: size)
    }

    static func quran(ofSize size: FontSize) -> Font {
        custom(.quran, size: size.fontSize(forMediumSize: arabicQuranTextFontSize))
    }
}

public extension UIFont {
    convenience init(_ font: FontName, size: CGFloat) {
        self.init(name: font.rawValue, size: size)!
    }

    // Translator

    static func translatorNameArabic(ofSize size: FontSize) -> UIFont {
        UIFont(.arabic, size: size.fontSize(forMediumSize: 20))
    }

    static func translatorNameEnglish(ofSize size: FontSize) -> UIFont {
        .systemFont(ofSize: size.fontSize(forMediumSize: 17))
    }

    static func translatorNameAmharic(ofSize size: FontSize) -> UIFont {
        UIFont(.amharic, size: size.fontSize(forMediumSize: 17))
    }

    // Quran

    static func arabicQuranText(ofSize size: FontSize) -> UIFont {
        UIFont(.quran, size: size.fontSize(forMediumSize: arabicQuranTextFontSize))
    }

    // Translations

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

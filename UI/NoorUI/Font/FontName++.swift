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

private let arabicQuranTextFontSize: CGFloat = 17
private let arabicTafseerTextFontSize: CGFloat = 21

public extension Font {
    static func quran(ofSize size: FontSize? = nil) -> Font {
        custom(.quran, size: size?.fontSize(forMediumSize: arabicQuranTextFontSize) ?? arabicQuranTextFontSize)
    }

    static func arabicTafseer() -> Font {
        custom(.arabic, size: arabicTafseerTextFontSize)
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

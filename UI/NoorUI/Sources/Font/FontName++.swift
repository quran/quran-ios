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

private let arabicQuranTextFontSize: CGFloat = 21
private let arabicTafseerTextFontSize: CGFloat = 21

extension Font {
    static func quran(ofSize size: FontSize? = nil) -> Font {
        custom(.quran, size: size?.fontSize(forMediumSize: arabicQuranTextFontSize) ?? arabicQuranTextFontSize)
    }
}

public extension Font {
    static func arabicTafseer() -> Font {
        custom(.arabic, size: arabicTafseerTextFontSize)
    }
}

//
//  PageText.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/23/17.
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

import Foundation
import QuranKit
import TranslationService

public struct TranslationText: Hashable {
    public let translation: Translation
    public let text: String
}

public struct VerseText: Hashable {
    public let verse: AyahNumber
    public let arabicText: String
    public let translations: [TranslationText]
    public let arabicPrefix: [String]
    public let arabicSuffix: [String]
}

public struct PageText: Hashable {
    public let page: Page
    public let verses: [VerseText]
}

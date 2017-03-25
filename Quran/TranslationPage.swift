//
//  TranslationPage.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/23/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

struct TranslationText {
    let translation: Translation
    let text: String
}

struct TranslationVerse {
    let ayah: AyahNumber
    let arabicText: String
    let translations: [TranslationText]
}

struct TranslationPage {
    let arabicPrefix: [String]
    let verses: [TranslationVerse]
    let arabicSuffix: [String]
}

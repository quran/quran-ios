//
//  VerseTextPersistence.swift
//  Quran
//
//  Created by Hossam Ghareeb on 6/20/16.
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

protocol SearchableTextPersistence {
    func autocomplete(term: String) throws -> [String]
    func search(for term: String, quran: Quran) throws -> [(verse: AyahNumber, text: String)]
}

protocol VerseTextPersistence: SearchableTextPersistence {
    func textForVerse(_ verse: AyahNumber) throws -> String
    func textForVerses(_ verses: [AyahNumber]) throws -> [AyahNumber: String]
}

enum RawTranslationText: Equatable {
    case string(String)
    case reference(AyahNumber)
}

protocol TranslationVerseTextPersistence: SearchableTextPersistence {
    func textForVerse(_ verse: AyahNumber) throws -> RawTranslationText
    func textForVerses(_ verses: [AyahNumber]) throws -> [AyahNumber: RawTranslationText]
}

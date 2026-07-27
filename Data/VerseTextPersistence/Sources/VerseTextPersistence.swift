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

import QuranKit
import QuranText

public protocol SearchableTextPersistence<Text> {
    associatedtype Text

    func autocomplete(term: String) async throws -> [Text]
    func search(for term: String, quran: Quran) async throws -> [(verse: AyahNumber, text: Text)]
}

public protocol VerseTextPersistence: SearchableTextPersistence<QuranText> {
    func textForVerse(_ verse: AyahNumber) async throws -> QuranText
    func textForVerses(_ verses: [AyahNumber]) async throws -> [AyahNumber: QuranText]
}

public enum TranslationTextPersistenceModel: Equatable {
    case string(String)
    case reference(AyahNumber)
}

public protocol TranslationVerseTextPersistence: SearchableTextPersistence<String> {
    func textForVerse(_ verse: AyahNumber) async throws -> TranslationTextPersistenceModel
    func textForVerses(_ verses: [AyahNumber]) async throws -> [AyahNumber: TranslationTextPersistenceModel]
}

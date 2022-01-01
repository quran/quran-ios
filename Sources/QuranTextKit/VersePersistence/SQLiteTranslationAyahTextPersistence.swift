//
//  SQLiteTranslationAyahTextPersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/21/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation
import QuranKit
import SQLite
import SQLitePersistence

class SQLiteTranslationVerseTextPersistence: ReadonlySQLitePersistence, VerseTextPersistence {
    static let table = Table("verses")

    let filePath: String
    private let persistence: GeneralVerseTextPersistence

    init(fileURL: URL, quran: Quran) {
        filePath = fileURL.absoluteString
        persistence = GeneralVerseTextPersistence(filePath: filePath,
                                                  table: Self.table,
                                                  quran: quran)
    }

    func textForVerses(_ verses: [AyahNumber]) throws -> [AyahNumber: String] {
        try validateFileExists()
        return try persistence.textForVerses(verses)
    }

    func textForVerse(_ verse: AyahNumber) throws -> String {
        try validateFileExists()
        return try persistence.textForVerse(verse)
    }

    func autocomplete(term: String) throws -> [String] {
        try validateFileExists()
        return try persistence.autocomplete(term: term)
    }

    func search(for term: String) throws -> [(verse: AyahNumber, text: String)] {
        try validateFileExists()
        return try persistence.search(for: term)
    }
}

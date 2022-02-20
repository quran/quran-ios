//
//  SQLiteTranslationVerseTextPersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/21/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation
import QuranKit
import SQLite
import SQLitePersistence

class SQLiteTranslationVerseTextPersistence: ReadonlySQLitePersistence, TranslationVerseTextPersistence {
    static let table = Table("verses")

    let filePath: String
    private let persistence: GeneralVerseTextPersistence

    init(fileURL: URL, quran: Quran) {
        filePath = fileURL.absoluteString
        persistence = GeneralVerseTextPersistence(filePath: filePath,
                                                  table: Self.table,
                                                  quran: quran)
    }

    func textForVerses(_ verses: [AyahNumber]) throws -> [AyahNumber: TranslationText] {
        try validateFileExists()
        return try persistence.textForVerses(verses, transform: textFromRow)
    }

    func textForVerse(_ verse: AyahNumber) throws -> TranslationText {
        try validateFileExists()
        return try persistence.textForVerse(verse, transform: textFromRow)
    }

    func autocomplete(term: String) throws -> [String] {
        try validateFileExists()
        return try persistence.autocomplete(term: term)
    }

    func search(for term: String) throws -> [(verse: AyahNumber, text: String)] {
        try validateFileExists()
        return try persistence.search(for: term)
    }

    private func textFromRow(_ row: Row) throws -> TranslationText {
        let stringText = Expression<String?>("text")
        let intText = Expression<Int?>("text")
        let quran = persistence.quran

        if let stringText = row[stringText] {
            // if the data is an Integer but saved as String, try to see if it's a valid verseId
            if let verseId = Int(stringText), verseId > 0 && verseId <= quran.verses.count {
                return referenceVerse(verseId)
            } else {
                return .string(stringText)
            }
        } else if let verseId = row[intText] {
            return referenceVerse(verseId)
        }
        throw PersistenceError.general("Text for verse is neither Int nor String. File: \(filePath.lastPathComponent)")
    }

    private func referenceVerse(_ verseId: Int) -> TranslationText {
        // VerseId saved is an index in the quran.verses starts with 0
        let verse = persistence.quran.verses[verseId - 1]
        return .reference(verse)
    }
}

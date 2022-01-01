//
//  WordTextPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 6/19/17.
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
import SQLite
import SQLitePersistence

protocol WordTextPersistence {
    func translationForWord(_ word: Word) throws -> String?
    func transliterationForWord(_ word: Word) throws -> String?
}

class SQLiteWordTextPersistence: ReadonlySQLitePersistence, WordTextPersistence {
    private struct Database {
        static let wordsTable = Table("words")
        struct Columns {
            static let word = Expression<Int>("word_position")
            static let translation = Expression<String?>("translation")
            static let transliteration = Expression<String?>("transliteration")
            static let sura = Expression<Int>("sura")
            static let ayah = Expression<Int>("ayah")
        }
    }

    private static let wordsTextPath = Bundle.main.path(forResource: "words", ofType: "db")!
    var filePath: String { Self.wordsTextPath }

    init() { }

    func translationForWord(_ word: Word) throws -> String? {
        try wordText(word, textColumn: Database.Columns.translation)
    }

    func transliterationForWord(_ word: Word) throws -> String? {
        try wordText(word, textColumn: Database.Columns.transliteration)
    }

    private func wordText(_ word: Word, textColumn: Expression<String?>) throws -> String? {
        try run { connection in
            let query = Database.wordsTable
                .select(textColumn)
                .filter(Database.Columns.sura == word.verse.sura.suraNumber &&
                    Database.Columns.ayah == word.verse.ayah &&
                    Database.Columns.word == word.wordNumber)
            let rows = try connection.prepare(query)
            let words = rowsToText(rows, textColumn: textColumn)
            guard words.count == 1 else {
                fatalError("Expected 1 word but found \(words.count) querying:\(word) - \(textColumn.template)")
            }
            return words[0]
        }
    }

    private func rowsToText(_ rows: AnySequence<Row>, textColumn: Expression<String?>) -> [String?] {
        var result: [String?] = []
        for row in rows {
            result.append(row[textColumn])
        }
        return result
    }
}

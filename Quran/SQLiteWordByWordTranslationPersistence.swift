//
//  SQLiteWordByWordTranslationPersistence.swift
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

import SQLite
import SQLitePersistence

class SQLiteWordByWordTranslationPersistence: ReadonlySQLitePersistence, WordByWordTranslationPersistence {

    private struct Database {
        static let wordsTable = Table("words")
        struct Columns {
            static let wordPosition = Expression<Int>("word_position")
            static let translation = Expression<String?>("translation")
            static let transliteration = Expression<String?>("transliteration")
            static let sura = Expression<Int>("sura")
            static let ayah = Expression<Int>("ayah")
        }
    }

    var filePath: String { return Files.wordsTextPath }

    func getWord(for position: AyahWord.Position, type: AyahWord.TextType) throws -> AyahWord {
        return try run { connection in
            let text: Expression<String?>
            switch type {
            case .translation: text = Database.Columns.translation
            case .transliteration: text = Database.Columns.transliteration
            }
            let query = Database.wordsTable
                .select(text)
                .filter(Database.Columns.sura == position.ayah.sura &&
                        Database.Columns.ayah == position.ayah.ayah &&
                        Database.Columns.wordPosition == position.position)
            let rows = try connection.prepare(query)
            let words = rowsToWord(rows, position: position, type: type)
            guard words.count == 1 else {
                fatalError("Expected 1 word but found \(words.count) querying:\(position) - \(type)")
            }
            return words[0]
        }
    }

    private func rowsToWord(_ rows: AnySequence<Row>, position: AyahWord.Position, type: AyahWord.TextType) -> [AyahWord] {
        var result: [AyahWord] = []
        for row in rows {
            let text: String?
            switch type {
            case .translation: text = row[Database.Columns.translation]
            case .transliteration: text = row[Database.Columns.transliteration]
            }

            let word = AyahWord(position: position, text: text, textType: type)
            result.append(word)
        }
        return result
    }
}

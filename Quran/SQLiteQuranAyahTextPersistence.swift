//
//  SQLiteQuranAyahTextPersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/20/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import SQLite
import SQLitePersistence

class SQLiteQuranAyahTextPersistence: ReadonlySQLitePersistence, QuranAyahTextPersistence, QuranShareableAyahTextPersistence {
    private struct Database {
        static let arabicTextTable = Table("arabic_text")
        static let shareTextTable = Table("share_text")
        struct Columns {
            static let sura = Expression<Int>("sura")
            static let ayah = Expression<Int>("ayah")
            static let text = Expression<String>("text")
        }
    }

    var filePath: String { return Files.quranTextPath }

    func getQuranAyahTextForNumber(_ number: AyahNumber) throws -> String {
        return try getTextFor(number: number, table: Database.arabicTextTable)
    }

    func getQuranShareableAyahTextForNumber(_ number: AyahNumber) throws -> String {
        return try getTextFor(number: number, table: Database.shareTextTable)
    }

    private func getTextFor(number: AyahNumber, table: Table) throws -> String {
        return try run { _ in
            let connection = try Connection(filePath, readonly: true)
            let query = table
                .select(Database.Columns.text)
                .filter(Database.Columns.sura == number.sura && Database.Columns.ayah == number.ayah)
            let rows = try connection.prepare(query)
            guard let first = rows.first(where: { _ in true }) else {
                throw PersistenceError.general("Cannot find any records for ayah '\(number)'")
            }
            return first[Database.Columns.text]
        }
    }
}

//
//  SQLiteTranslationAyahTextPersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/21/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import SQLite
import SQLitePersistence

class SQLiteTranslationAyahTextPersistence: ReadonlySQLitePersistence, TranslationAyahTextPersistence {
    private struct Database {
        static let table = Table("verses")
        struct Columns {
            static let sura = Expression<Int>("sura")
            static let ayah = Expression<Int>("ayah")
            static let text = Expression<String>("text")
        }
    }

    let filePath: String

    init(filePath: String) {
        self.filePath = filePath
    }

    func getTranslationAyahTextForNumber(_ number: AyahNumber) throws -> String? {
        try validateFileExists()

        return try run { connection in
            let query = Database.table.filter(Database.Columns.sura == number.sura &&
                                              Database.Columns.ayah == number.ayah)
            let rows = try connection.prepare(query)
            guard let first = rows.first(where: { _ in true }) else {
                return nil
            }
            return first[Database.Columns.text]
        }
    }
}

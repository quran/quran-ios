//
//  SQLiteTranslationTextPersistence.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/13/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import SQLite

class SQLiteTranslationTextPersistence: AyahTextPersistence, ReadonlySQLitePersistence {

    private struct Verses {
        static let table = Table("verses")
        static let sura = Expression<Int>("sura")
        static let ayah = Expression<Int>("ayah")
        static let text = Expression<String>("text")
    }

    let filePath: String

    init(filePath: String) {
        self.filePath = filePath
    }

    func getAyahTextForNumber(_ number: AyahNumber) throws -> String {
        return try run { connection in

            let query = Verses.table.filter(Verses.sura == number.sura && Verses.ayah == number.ayah)
            let rows = try connection.prepare(query)
            guard let first = rows.first(where: { _ in true }) else {
                throw PersistenceError.general("Cannot find any records for ayah '\(number)'")
            }
            return first[Verses.text]
        }
    }

    func getOptionalAyahText(forNumber number: AyahNumber) throws -> String? {
        return try run { connection in

            let query = Verses.table.filter(Verses.sura == number.sura && Verses.ayah == number.ayah)
            let rows = try connection.prepare(query)
            guard let first = rows.first(where: { _ in true }) else {
                return nil
            }
            return first[Verses.text]
        }
    }
}

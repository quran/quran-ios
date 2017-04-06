//
//  SQLiteArabicTextPersistence.swift
//  Quran
//
//  Created by Hossam Ghareeb on 6/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import SQLite

class SQLiteArabicTextPersistence: AyahTextPersistence, ReadonlySQLitePersistence {

    fileprivate struct Columns {
        let sura = Expression<Int>("sura")
        let ayah = Expression<Int>("ayah")
        let text = Expression<String>("text")
    }

    fileprivate let arabicTextTable = Table("arabic_text")
    fileprivate let columns = Columns()

    var filePath: String { return Files.quranTextPath }

    func getAyahTextForNumber(_ number: AyahNumber) throws -> String {
        return try run { connection in
            let query = arabicTextTable.filter(columns.sura == number.sura && columns.ayah == number.ayah)
            let rows = try connection.prepare(query)

            guard let first = rows.first(where: { _ in true}) else {
                throw PersistenceError.general("Cannot find any records for ayah '\(number)'")
            }
            return first[columns.text]
        }
    }

    func getOptionalAyahText(forNumber number: AyahNumber) throws -> String? {
        return try run { connection in
            let query = arabicTextTable.filter(columns.sura == number.sura && columns.ayah == number.ayah)
            let rows = try connection.prepare(query)

            guard let first = rows.first(where: { _ in true}) else {
                return nil
            }
            return first[columns.text]
        }
    }
}

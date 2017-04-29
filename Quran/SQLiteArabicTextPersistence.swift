//
//  SQLiteArabicTextPersistence.swift
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

import UIKit
import SQLite
import SQLitePersistence

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

            guard let first = rows.first(where: { _ in true }) else {
                throw PersistenceError.general("Cannot find any records for ayah '\(number)'")
            }
            return first[columns.text]
        }
    }

    func getOptionalAyahText(forNumber number: AyahNumber) throws -> String? {
        return try run { connection in
            let query = arabicTextTable.filter(columns.sura == number.sura && columns.ayah == number.ayah)
            let rows = try connection.prepare(query)

            guard let first = rows.first(where: { _ in true }) else {
                return nil
            }
            return first[columns.text]
        }
    }
}

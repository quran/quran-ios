//
//  SQLiteTranslationTextPersistence.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/13/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import SQLite

class SQLiteTranslationTextPersistence: AyahTextPersistence {

    fileprivate struct Columns {
        let sura = Expression<Int>("sura")
        let ayah = Expression<Int>("ayah")
        let text = Expression<String>("text")
    }

    fileprivate let translationTextTable = Table("verses")
    fileprivate let columns = Columns()

    fileprivate var db: LazyConnectionWrapper

    init(databaseFileURL: URL) {
        db = LazyConnectionWrapper(sqliteFilePath: databaseFileURL.absoluteString, readonly: true)
    }

    func getAyahTextForNumber(_ number: AyahNumber) throws -> String {
        let query = translationTextTable.filter(columns.sura == number.sura && columns.ayah == number.ayah)

        do {
            let rows = try db.getOpenConnection().prepare(query)

            guard let first = rows.first(where: { _ in true}) else {
                throw PersistenceError.general("Cannot find any records for ayah '\(number)'")
            }
            return first[columns.text]
        } catch {
            Crash.recordError(error, reason: "Cannot get ayah text for \(number)")
            throw PersistenceError.query(error)
        }
    }
}

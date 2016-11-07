//
//  SQLiteAyahTextPersistence.swift
//  Quran
//
//  Created by Hossam Ghareeb on 6/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import SQLite

class SQLiteAyahTextPersistence: AyahTextPersistence {

    fileprivate struct Columns {
        let sura = Expression<Int>("sura")
        let ayah = Expression<Int>("ayah")
        let text = Expression<String>("text")
    }

    fileprivate let arabicTextTable = Table("arabic_text")
    fileprivate let columns = Columns()

    fileprivate var db: LazyConnectionWrapper = { LazyConnectionWrapper(sqliteFilePath: Files.quranTextPath, readonly: true) }()

    func getAyahTextForNumber(_ number: AyahNumber) throws -> String {
        let query = arabicTextTable.filter(columns.sura == number.sura && columns.ayah == number.ayah)

        do {
            let rows = try db.getOpenConnection().prepare(query)

            guard let first = rows.first(where: { _ in true}) else {
                throw PersistenceError.general(description: "Cannot find any records for ayah '\(number)'")
            }
            return first[columns.text]
        } catch {
            Crash.recordError(error, reason: "Cannot get ayah text for \(number)")
            throw PersistenceError.queryError(error: error)
        }
    }
}

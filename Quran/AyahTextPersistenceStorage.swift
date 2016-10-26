//
//  AyahTextPersistenceStorage.swift
//  Quran
//
//  Created by Hossam Ghareeb on 6/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import SQLite

class AyahTextPersistenceStorage: AyahTextStorageProtocol {

    fileprivate struct Columns {
        let sura = Expression<Int>("sura")
        let ayah = Expression<Int>("ayah")
        let text = Expression<String>("text")
    }

    fileprivate let arabicTextTable = Table("arabic_text")
    fileprivate let columns = Columns()

    fileprivate var db: LazyConnectionWrapper = {
        let file = String(format: "images_\(quranImagesSize)/databases/quran.ar")
        guard let path = Bundle.main.path(forResource: file, ofType: "db") else {
            fatalError("Unable to find ayahinfo database in resources")
        }

        return LazyConnectionWrapper(sqliteFilePath: path, readonly: true)
    }()

    func getAyahTextForNumber(_ number: AyahNumber) throws -> String {
        let query = arabicTextTable.filter(columns.sura == number.sura && columns.ayah == number.ayah)


        do {
            for row in try db.connection.prepare(query) {
                let text = row[columns.text]
                return text
            }
            return ""
        } catch {
            Crash.recordError(error)
            throw PersistenceError.queryError(error: error)
        }
    }
}

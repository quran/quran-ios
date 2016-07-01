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

    private struct Columns {
        let sura = Expression<Int>("sura")
        let ayah = Expression<Int>("ayah")
        let text = Expression<String>("text")
    }

    private let arabicTextTable = Table("arabic_text")
    private let columns = Columns()

    private var db: LazyConnectionWrapper = {
        let file = String(format: "images_\(quranImagesSize)/databases/quran.ar")
        guard let path = NSBundle.mainBundle().pathForResource(file, ofType: "db") else {
            fatalError("Unable to find ayahinfo database in resources")
        }

        return LazyConnectionWrapper(sqliteFilePath: path, readonly: true)
    }()

    func getAyahTextForNumber(number: AyahNumber) throws -> String {
        let query = arabicTextTable.filter(columns.sura == number.sura && columns.ayah == number.ayah)


        do {
            for row in try db.connection.prepare(query) {
                let text = row[columns.text]
                return text
            }
            return ""
        } catch {
            Crash.recordError(error)
            throw PersistenceError.QueryError(error: error)
        }
    }
}

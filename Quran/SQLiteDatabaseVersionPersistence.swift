//
//  SQLiteDatabaseVersionPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/12/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import SQLite

struct SQLiteDatabaseVersionPersistence: DatabaseVersionPersistence, ReadonlySQLitePersistence {

    private struct Properties {
        static let table = Table("properties")
        static let property = Expression<String>("property")
        static let value = Expression<String>("value")
    }

    let filePath: String

    init(filePath: String) {
        self.filePath = filePath
    }

    func getTextVersion() throws -> Int {
        return try run { connection in

            let query = Properties.table.filter(Properties.property == "text_version")
            let rows = try connection.prepare(query)
            guard let first = rows.first(where: { _ in true }) else {
                throw PersistenceError.general("Cannot find any records for text_version")
            }
            return cast(Int(first[Properties.value]))
        }
    }
}

//
//  SQLiteDatabaseVersionPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/12/17.
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

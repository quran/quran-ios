//
//  SQLiteDatabaseVersionPersistence.swift
//  
//
//  Created by Mohamed Afifi on 2023-05-22.
//

import SQLite
import SQLitePersistence

struct SQLiteDatabaseVersionPersistence: DatabaseVersionPersistence, ReadonlySQLitePersistence {
    private struct Properties {
        static let table = Table("properties")
        static let property = Expression<String>("property")
        static let value = Expression<String>("value")
    }

    let filePath: String

    func getTextVersion() async throws -> Int {
        try run { connection in

            let query = Properties.table.filter(Properties.property == "text_version")
            let rows = try connection.prepare(query)
            guard let first = rows.first(where: { _ in true }) else {
                throw PersistenceError.general("Cannot find any records for text_version")
            }
            return Int(first[Properties.value])!
        }
    }
}

//
//  GRDBDatabaseVersionPersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-22.
//

import Foundation
import GRDB
import SQLitePersistence

struct GRDBDatabaseVersionPersistence: DatabaseVersionPersistence {
    let db: DatabaseWriter

    init(db: DatabaseWriter) {
        self.db = db
    }

    init(fileURL: URL) throws {
        self.init(db: try DatabasePool.newInstance(filePath: fileURL.path, readOnly: true))
    }

    func getTextVersion() async throws -> Int {
        try await db.write { db in
            let property = try GRDBProperty
                .filter(GRDBProperty.Columns.property == "text_version")
                .fetchOne(db)
            guard let property else {
                throw RecordError.recordNotFound(
                    databaseTableName: GRDBProperty.databaseTableName, key: [:]
                )
            }
            return Int(property.value)!
        }
    }
}

private struct GRDBProperty: Decodable, FetchableRecord, TableRecord {
    var property: String
    var value: String

    enum Columns {
        static let property = Column("property")
        static let value = Column("value")
    }

    static var databaseTableName: String {
        "properties"
    }
}

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
    let db: DatabaseConnection

    init(db: DatabaseConnection) {
        self.db = db
    }

    init(fileURL: URL) {
        self.init(db: DatabaseConnection(url: fileURL))
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
        static let property = Column(CodingKeys.property)
        static let value = Column(CodingKeys.value)
    }

    static var databaseTableName: String {
        "properties"
    }
}

//
//  GRDBDatabaseVersionPersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-22.
//

import Foundation
import GRDB
import SQLitePersistence

public struct GRDBDatabaseVersionPersistence: DatabaseVersionPersistence {
    // MARK: Lifecycle

    init(db: DatabaseConnection) {
        self.db = db
    }

    public init(fileURL: URL) {
        self.init(db: DatabaseConnection(url: fileURL))
    }

    // MARK: Public

    public func getTextVersion() async throws -> Int {
        try await db.read { db in
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

    // MARK: Internal

    let db: DatabaseConnection
}

private struct GRDBProperty: Decodable, FetchableRecord, TableRecord {
    enum Columns {
        static let property = Column(CodingKeys.property)
        static let value = Column(CodingKeys.value)
    }

    static var databaseTableName: String {
        "properties"
    }

    var property: String
    var value: String
}

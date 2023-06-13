//
//  GRDBActiveTranslationsPersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-21.
//

import Foundation
import GRDB
import QuranText
import SQLitePersistence
import VLogging

public struct GRDBActiveTranslationsPersistence: ActiveTranslationsPersistence {
    let db: DatabaseConnection

    init(db: DatabaseConnection) {
        self.db = db
        do {
            try migrator.migrate(db)
        } catch {
            logger.error("Error while performing Translations migrations. Error: \(error)")
        }
    }

    public init(directory: URL) {
        let fileURL = directory.appendingPathComponent("translations.db", isDirectory: false)
        self.init(db: DatabaseConnection(url: fileURL))
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createTranslations") { db in
            try db.create(table: "translations", options: .ifNotExists) { table in
                table.primaryKey("_ID", .integer)
                table.column("name", .text).notNull()
                table.column("translator", .text)
                table.column("translator_foreign", .text)
                table.column("fileURL", .text).notNull()
                table.column("filename", .text).notNull()
                table.column("languageCode", .text).notNull()
                table.column("version", .integer).notNull()
                table.column("installedVersion", .integer)
            }
        }
        return migrator
    }

    public func retrieveAll() async throws -> [Translation] {
        try await db.read { db in
            let grdbTranslations = try GRDBTranslation.fetchAll(db)
            return grdbTranslations.map { $0.toTranslation() }
        }
    }

    public func insert(_ translation: Translation) async throws {
        try await db.write { db in
            var grdbTranslation = GRDBTranslation(translation)
            try grdbTranslation.insert(db)
        }
    }

    public func remove(_ translation: Translation) async throws {
        try await db.write { db in
            let grdbTranslation = GRDBTranslation(translation)
            try grdbTranslation.delete(db)
        }
    }

    public func update(_ translation: Translation) async throws {
        try await db.write { db in
            let grdbTranslation = GRDBTranslation(translation)
            try grdbTranslation.update(db)
        }
    }
}

// MARK: - Database Model

private struct GRDBTranslation: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int
    var displayName: String
    var translator: String?
    var translatorForeign: String?
    var fileURL: String
    var fileName: String
    var languageCode: String
    var version: Int
    var installedVersion: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_ID"
        case displayName = "name"
        case translator
        case translatorForeign = "translator_foreign"
        case fileURL
        case fileName = "filename"
        case languageCode
        case version
        case installedVersion
    }

    // Define the database table
    static var databaseTableName: String {
        "translations"
    }
}

// Mapping functions
extension GRDBTranslation {
    init(_ translation: Translation) {
        id = translation.id
        displayName = translation.displayName
        translator = translation.translator
        translatorForeign = translation.translatorForeign
        fileURL = translation.fileURL.absoluteString
        fileName = translation.fileName
        languageCode = translation.languageCode
        version = translation.version
        installedVersion = translation.installedVersion
    }

    func toTranslation() -> Translation {
        Translation(id: id,
                    displayName: displayName,
                    translator: translator,
                    translatorForeign: translatorForeign,
                    fileURL: URL(string: fileURL)!,
                    fileName: fileName,
                    languageCode: languageCode,
                    version: version,
                    installedVersion: installedVersion)
    }
}

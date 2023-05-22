//
//  GRDBActiveTranslationsPersistence.swift
//  
//
//  Created by Mohamed Afifi on 2023-05-21.
//

import Foundation
import SQLitePersistence
import GRDB
import VLogging

struct GRDBActiveTranslationsPersistence: ActiveTranslationsPersistence {
    let db: DatabaseWriter

    init(db: DatabaseWriter) {
        self.db = db
        do {
            try migrator.migrate(db)
        } catch {
            logger.error("Error while performing Translations migrations. Error: \(error)")
        }
    }

    init(directory: String) {
        let filePath = directory.stringByAppendingPath("translations.db")
        self.init(db: DatabasePool.unsafeNewInstance(filePath: filePath))
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

    func retrieveAll() async throws -> [Translation] {
        try await db.read { db in
            let grdbTranslations = try GRDBTranslation.fetchAll(db)
            return grdbTranslations.map { $0.toTranslation() }
        }
    }

    func insert(_ translation: Translation) async throws {
        try await db.write { db in
            var grdbTranslation = GRDBTranslation(translation)
            try grdbTranslation.insert(db)
        }
    }

    func remove(_ translation: Translation) async throws {
        try await db.write { db in
            let grdbTranslation = GRDBTranslation(translation)
            try grdbTranslation.delete(db)
        }
    }

    func update(_ translation: Translation) async throws {
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
        return "translations"
    }
}

// Mapping functions
extension GRDBTranslation {
    init(_ translation: Translation) {
        self.id = translation.id
        self.displayName = translation.displayName
        self.translator = translation.translator
        self.translatorForeign = translation.translatorForeign
        self.fileURL = translation.fileURL.absoluteString
        self.fileName = translation.fileName
        self.languageCode = translation.languageCode
        self.version = translation.version
        self.installedVersion = translation.installedVersion
    }

    func toTranslation() -> Translation {
        return Translation(id: id,
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

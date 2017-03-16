//
//  SQLiteActiveTranslationsPersistence.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/13/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import SQLite

extension Queue {
    static let translations = Queue(queue: DispatchQueue(label: "com.quran.translations"))
}
extension DispatchQueue {
    static let translations = Queue.translations.queue
}

struct SQLiteActiveTranslationsPersistence: ActiveTranslationsPersistence, SQLitePersistence {

    let version: UInt = 1
    var filePath: String {
        return Files.databasesPath.stringByAppendingPath("translations.db")
    }

    private struct Translations {
        static let table = Table("translations")
        static let id = Expression<Int>("_ID")
        static let name = Expression<String>("name")
        static let translator = Expression<String?>("translator")
        static let translatorForeign = Expression<String?>("translator_foreign")
        static let fileURL = Expression<String>("fileURL")
        static let fileName = Expression<String>("filename")
        static let version = Expression<Int>("version")
        static let installedVersion = Expression<Int?>("installedVersion")
    }

    func onCreate(connection: Connection) throws {
        // translations table
        try connection.run(Translations.table.create { builder in
            builder.column(Translations.id, primaryKey: true)
            builder.column(Translations.name)
            builder.column(Translations.translator)
            builder.column(Translations.translatorForeign)
            builder.column(Translations.fileURL)
            builder.column(Translations.fileName)
            builder.column(Translations.version)
            builder.column(Translations.installedVersion)
        })
    }

    func retrieveAll() throws -> [Translation] {
        return try run { connection in
            let query = Translations.table.order(Translations.name.asc)
            let rows = try connection.prepare(query)
            let bookmarks = convert(rowsToTranslations: rows)
            return bookmarks
        }
    }

    func insert(_ translation: Translation) throws {
        return try run { connection in
            let insert = Translations.table.insert(
                Translations.id <- translation.id,
                Translations.name <- translation.displayName,
                Translations.translator <- translation.translator,
                Translations.translatorForeign <- translation.translatorForeign,
                Translations.fileURL <- translation.fileURL.absoluteString,
                Translations.fileName <- translation.fileName,
                Translations.version <- translation.version,
                Translations.installedVersion <- translation.installedVersion)
            try connection.run(insert)
        }
    }

    func update(_ translation: Translation) throws {
        return try run { connection in
            let update = Translations.table
                .where(Translations.id == translation.id)
                .update(
                    Translations.name <- translation.displayName,
                    Translations.translator <- translation.translator,
                    Translations.translatorForeign <- translation.translatorForeign,
                    Translations.fileURL <- translation.fileURL.absoluteString,
                    Translations.fileName <- translation.fileName,
                    Translations.version <- translation.version,
                    Translations.installedVersion <- translation.installedVersion)
            try connection.run(update)
        }
    }

    func remove(_ translation: Translation) throws {
        return try run { connection in
            let filter = Translations.table.filter(Translations.id == translation.id)
            try connection.run(filter.delete())
        }
    }

    private func convert(rowsToTranslations rows: AnySequence<Row>) -> [Translation] {
        var translations: [Translation] = []
        for row in rows {
            let id = row[Translations.id]
            let name = row[Translations.name]
            let translator = row[Translations.translator]
            let translatorForeign = row[Translations.translatorForeign]
            let fileURL = row[Translations.fileURL]
            let fileName = row[Translations.fileName]
            let version = row[Translations.version]
            let installedVersion = row[Translations.installedVersion]
            let translation = Translation(id: id, displayName: name, translator: translator,
                                          translatorForeign: translatorForeign,
                                          fileURL: cast(URL(string: fileURL)), fileName: fileName,
                                          version: version, installedVersion: installedVersion)
            translations.append(translation)
        }
        return translations
    }
}

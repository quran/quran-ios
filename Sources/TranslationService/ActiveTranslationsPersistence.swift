//
//  ActiveTranslationsPersistence.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/13/17.
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

import Foundation
import SQLite
import SQLitePersistence

protocol ActiveTranslationsPersistence {
    func retrieveAll() async throws -> [Translation]
    func insert(_ translation: Translation) async throws
    func remove(_ translation: Translation) async throws
    func update(_ translation: Translation) async throws
}

struct SQLiteActiveTranslationsPersistence: ActiveTranslationsPersistence, SQLitePersistence {
    let version: UInt = 1
    let filePath: String

    init(directory: String) {
        filePath = directory.stringByAppendingPath("translations.db")
    }

    private struct Translations {
        static let table = Table("translations")
        static let id = Expression<Int>("_ID")
        static let name = Expression<String>("name")
        static let translator = Expression<String?>("translator")
        static let translatorForeign = Expression<String?>("translator_foreign")
        static let fileURL = Expression<String>("fileURL")
        static let fileName = Expression<String>("filename")
        static let languageCode = Expression<String>("languageCode")
        static let version = Expression<Int>("version")
        static let installedVersion = Expression<Int?>("installedVersion")
    }

    func onCreate(connection: Connection) throws {
        // translations table
        try connection.run(Translations.table.create(ifNotExists: true) { builder in
            builder.column(Translations.id, primaryKey: true)
            builder.column(Translations.name)
            builder.column(Translations.translator)
            builder.column(Translations.translatorForeign)
            builder.column(Translations.fileURL)
            builder.column(Translations.fileName)
            builder.column(Translations.languageCode)
            builder.column(Translations.version)
            builder.column(Translations.installedVersion)
        })
    }

    func retrieveAll() async throws -> [Translation] {
        try run { connection in
            let query = Translations.table.order(Translations.name.asc)
            let rows = try connection.prepare(query)
            let bookmarks = convert(rowsToTranslations: rows)
            return bookmarks
        }
    }

    func insert(_ translation: Translation) async throws {
        try run { connection in
            let insert = Translations.table.insert(
                Translations.id <- translation.id,
                Translations.name <- translation.displayName,
                Translations.translator <- translation.translator,
                Translations.translatorForeign <- translation.translatorForeign,
                Translations.fileURL <- translation.fileURL.absoluteString,
                Translations.fileName <- translation.fileName,
                Translations.languageCode <- translation.languageCode,
                Translations.version <- translation.version,
                Translations.installedVersion <- translation.installedVersion
            )
            try connection.run(insert)
        }
    }

    func update(_ translation: Translation) async throws {
        try run { connection in
            let update = Translations.table
                .where(Translations.fileName == translation.fileName)
                .update(
                    Translations.name <- translation.displayName,
                    Translations.translator <- translation.translator,
                    Translations.translatorForeign <- translation.translatorForeign,
                    Translations.fileURL <- translation.fileURL.absoluteString,
                    Translations.languageCode <- translation.languageCode,
                    Translations.version <- translation.version,
                    Translations.installedVersion <- translation.installedVersion
                )
            try connection.run(update)
        }
    }

    func remove(_ translation: Translation) async throws {
        try run { connection in
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
            let fileURLString = row[Translations.fileURL]
            let fileURL = URL(string: fileURLString)!
            let fileName = row[Translations.fileName]
            let languageCode = row[Translations.languageCode]
            let version = row[Translations.version]
            let installedVersion = row[Translations.installedVersion]
            let translation = Translation(
                id: id, displayName: name,
                translator: translator,
                translatorForeign: translatorForeign,
                fileURL: fileURL,
                fileName: fileName,
                languageCode: languageCode,
                version: version,
                installedVersion: installedVersion
            )
            translations.append(translation)
        }
        return translations
    }
}

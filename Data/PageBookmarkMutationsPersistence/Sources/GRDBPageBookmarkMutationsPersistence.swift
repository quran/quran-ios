//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 10/02/2025.
//

import Foundation
import SQLitePersistence
import VLogging
import GRDB
import Combine

struct GRDBPageBookmarkMutationsPersistence: PageBookmarkMutationsPersistence {
    private let db: DatabaseConnection

    init(db: DatabaseConnection) {
        self.db = db
        do {
            try migrator.migrate(db)
        } catch {
            logger.error("Failed to to do Mutated Page Bookmarks migration: \(error)")
        }
    }

    func bookmarksPublisher() throws -> AnyPublisher<[MutatedPageBookmarkModel], Never> {
        fatalError("Not implemented")
    }

    func bookmarks() async throws -> [MutatedPageBookmarkModel] {
        try await db.read {
            try GRDBMutatedPageBookmark.fetchAll($0).map{ $0.toMutatedBookmarkModel() }
        }
    }

    func createBookmark(page: Int) async throws {
        try await db.write { db in
            var instance = GRDBMutatedPageBookmark(page: page)
            try instance.insert(db)
        }
    }

    func removeBookmark(page: Int) async throws {
        fatalError("Not implemented")
    }

    func clear() async throws {
        fatalError()
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createPageBookmarks") { db in
            try db.create(table: GRDBMutatedPageBookmark.databaseTableName, options: .ifNotExists) { table in
                table.column("page", .integer).primaryKey()
                table.column("deleted", .boolean).notNull().defaults(to: false)
                table.column("modification_date", .datetime).notNull()
            }
        }
        return migrator
    }
}

private struct GRDBMutatedPageBookmark: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    enum CodingKeys: String, CodingKey {
        case page
        case modificationDate = "modification_date"
        case deleted
    }

    static var databaseTableName: String { "mutated_page_bookmarks" }

    var page: Int
    var modificationDate: Date
    var deleted: Bool

    var id: Int { page }
}

private extension GRDBMutatedPageBookmark {

    init(page: Int) {
        self.init(page: page, modificationDate: Date(), deleted: false)
    }

    func toMutatedBookmarkModel() -> MutatedPageBookmarkModel {
        .init(page: page, modificationDate: modificationDate, deleted: deleted)
    }
}

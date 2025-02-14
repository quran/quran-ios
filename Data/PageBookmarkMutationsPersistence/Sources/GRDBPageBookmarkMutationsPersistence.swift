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
        try db.readPublisher { db in
            try GRDBMutatedPageBookmark.fetchAll(db)
                .map{ $0.toMutatedBookmarkModel() }
        }
        .catch { error in
            logger.error("Error in page bookmarks publisher: \(error)")
            return Empty<[MutatedPageBookmarkModel], Never>()
        }
        .eraseToAnyPublisher()
    }

    func bookmarks() async throws -> [MutatedPageBookmarkModel] {
        try await db.read {
            try GRDBMutatedPageBookmark.fetchAll($0)
                .map{ $0.toMutatedBookmarkModel() }
        }
    }

    func createBookmark(page: Int) async throws {
        if let persisted = try await fetchPesistedRecord(for: page) {
            if persisted.remoteID != nil && persisted.deleted {
                // Recreating a synced bookmark that was deleted locally.
                // Keep the deletion event for the synced bookmark, and make a new unsynced one.
                try await createBookmark(page: page)
            } 
            else {
                throw PageBookmarkMutationsPersistenceError.bookmarkAlreadyExists(page: page)
            }
        }
        else {
            try await db.write { db in
                var instance = GRDBMutatedPageBookmark(page: page)
                try instance.insert(db)
            }
        }
    }

    func removeBookmark(_ bookmark: MutatedPageBookmarkModel) async throws {
        if let persisted = try await fetchPesistedRecord(for: bookmark.page), persisted.remoteID == nil {
            // Record hasn't been synced yet. Remove it!
            try await deleteRecord(for: bookmark.page)
        } else {
            // Record is synced. Create deletion record.
            try await createDeletedRecord(for: bookmark)
        }
    }

    private func fetchRecord(for page: Int) async throws -> GRDBMutatedPageBookmark? {
        try await db.read { db in
            try GRDBMutatedPageBookmark.fetchOne(db, id: page)
        }
    }

    private func fetchPesistedRecord(for page: Int) async throws -> GRDBMutatedPageBookmark? {
        try await db.read { db in
            try GRDBMutatedPageBookmark.fetchOne(db.makeStatement(sql: "SELECT * from \(GRDBMutatedPageBookmark.databaseTableName) WHERE page=? AND deleted=false"), arguments: ["\(page)"])
        }
    }

    private func createDeletedRecord(for bookmark: MutatedPageBookmarkModel) async throws {
        try await db.write { db in
            var instance = GRDBMutatedPageBookmark(remoteID: bookmark.remoteID,
                                                   page: bookmark.page,
                                                   modificationDate: Date(),
                                                   deleted: true)
            try instance.insert(db)
        }
    }

    private func deleteRecord(for page: Int) async throws {
        try await db.write { db in
            try db.execute(sql: "DELETE FROM \(GRDBMutatedPageBookmark.databaseTableName) WHERE page = ?", arguments: [page])
        }
    }

    func clear() async throws {
        try await db.write { db in
            // TODO: Log this?
            _ = try GRDBMutatedPageBookmark.deleteAll(db)
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createPageBookmarks") { db in
            try db.create(table: GRDBMutatedPageBookmark.databaseTableName, options: .ifNotExists) { table in
                table.column("page", .integer).notNull()
                table.column("remote_id", .text)
                table.column("deleted", .boolean).notNull().defaults(to: false)
                table.column("modification_date", .datetime).notNull()
            }
        }
        return migrator
    }
}

private struct GRDBMutatedPageBookmark: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    enum CodingKeys: String, CodingKey {
        case remoteID = "remote_id"
        case page
        case modificationDate = "modification_date"
        case deleted
    }

    static var databaseTableName: String { "mutated_page_bookmarks" }

    var remoteID: String?
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
        .init(remoteID: remoteID, page: page, modificationDate: modificationDate, deleted: deleted)
    }
}

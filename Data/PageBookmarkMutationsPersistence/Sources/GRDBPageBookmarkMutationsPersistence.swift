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
        try await db.read { db in
            try GRDBMutatedPageBookmark.fetchAll(db)
                .map{ $0.toMutatedBookmarkModel() }
        }
    }

    func createBookmark(page: Int) async throws {
        let persisted = try await fetchCreatedBookmark(forPage: page)
        if persisted?.deleted == false {
            throw PageBookmarkMutationsPersistenceError.bookmarkAlreadyExists(page: page)
        }

        // If `persisted` is still not nil, then it's been deleted, and it was a synced one.
        // In this case, it's safe to create a new unsynced bookmark, as a way to update
        // the bookmark's modification date.
        // The other case for this code branch is that `persisted` is nil.
        try await db.write { db in
            var instance = GRDBMutatedPageBookmark(page: page)
            try instance.insert(db)
        }
    }

    func removeBookmark(_ input: MutatedPageBookmarkModel) async throws {
        let hasCreatedRecord = try await fetchCreatedBookmark(forPage: input.page) != nil

        if hasCreatedRecord && input.isSynced {
            let reason = "Deleting a synced bookmark on a page, after creating an unsynced one."
            throw PageBookmarkMutationsPersistenceError.illegalState(reason: reason, page: input.page)
        } else if hasCreatedRecord && !input.isSynced {
            try await deleteAll(forPage: input.page)
        } else if input.isSynced {
            try await createBookamrkMarkedForDelete(for: input)
        } else {
            let reason = "Deleting an unsynced bookmark on a page with no record of being created."
            throw PageBookmarkMutationsPersistenceError.illegalState(reason: reason, page: input.page)
        }
    }

    /// Fetches a bookmark for the given page that isn't marked for deletion.
    private func fetchCreatedBookmark(forPage page: Int) async throws -> GRDBMutatedPageBookmark? {
        try await db.read { db in
            try GRDBMutatedPageBookmark.fetchOne(db.makeStatement(sql: "SELECT * from \(GRDBMutatedPageBookmark.databaseTableName) WHERE page=? AND deleted=false"), arguments: ["\(page)"])
        }
    }

    private func createBookamrkMarkedForDelete(for bookmark: MutatedPageBookmarkModel) async throws {
        try await db.write { db in
            var instance = GRDBMutatedPageBookmark(remoteID: bookmark.remoteID,
                                                   page: bookmark.page,
                                                   modificationDate: Date(),
                                                   deleted: true)
            try instance.insert(db)
        }
    }

    private func deleteAll(forPage page: Int) async throws {
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
                // TODO: Add an auto-incrementing primary key?
                table.column("page", .integer).notNull()
                table.column("remote_id", .text)
                table.column("deleted", .boolean).notNull().defaults(to: false)
                table.column("modification_date", .datetime).notNull()
            }
        }
        return migrator
    }
}

/// Imperatives:
/// - If remote ID is not nil, then `deleted` must be true.
/// - If remote ID is nil, then `deleted` can't be true
/// - If there are two records with the same `page`, then the first must be a deletion for a synced bookmark, so the remote
///   ID must be nil, and the second must be a new unsynced one.
/// - Otherwise, there can't be two records for the same `page`.
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

private extension MutatedPageBookmarkModel {

    var isSynced: Bool { remoteID != nil }
}

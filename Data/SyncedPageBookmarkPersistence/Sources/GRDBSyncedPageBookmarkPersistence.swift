//
//  GRDBSyncedPageBookmarkPersistence.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 31/01/2025.
//

import Combine
import Foundation
import GRDB
import SQLitePersistence
import VLogging

public struct GRDBSyncedPageBookmarkPersistence: SyncedPageBookmarkPersistence {
    private let db: DatabaseConnection

    init(db: DatabaseConnection) {
        self.db = db
        do {
            try migrator.migrate(db)
        } catch {
            logger.error("Failed to to do Page Bookmarks migration: \(error)")
        }
    }

    public init(directory: URL) {
        let fileURL = directory.appendingPathComponent("pagebookmarks.db", isDirectory: false)
        self.init(db: DatabaseConnection(url: fileURL, readonly: false))
    }

    public func syncedPageBookmarksPublisher() throws -> AnyPublisher<[SyncedPageBookmarkPersistenceModel], Never> {
        do {
            return try db.readPublisher { db in
                try GRDBSyncedPageBookmark.fetchAll(db).map { $0.toPersistenceModel() }
            }
            .catch { error in
                logger.error("Error in page bookmarks publisher: \(error)")
                return Empty<[SyncedPageBookmarkPersistenceModel], Never>()
            }
            .eraseToAnyPublisher()
        } catch {
            logger.error("Failed to create a publisher for page bookmarks: \(error)")
            return Empty<[SyncedPageBookmarkPersistenceModel], Never>().eraseToAnyPublisher()
        }
    }

    public func insert(bookmark: SyncedPageBookmarkPersistenceModel) async throws {
        try await db.write { db in
            var bookmark = GRDBSyncedPageBookmark(bookmark)
            try bookmark.insert(db)
        }
    }

    public func removeBookmark(withRemoteID remoteID: String) async throws {
        guard !remoteID.isEmpty else {
            logger.critical("[SyncedPageBookmarkPersistence] Attempted to remove a bookmark with an empty remote ID.")
            fatalError()
        }
        try await db.write { db in
            try db.execute(sql: "DELETE FROM \(GRDBSyncedPageBookmark.databaseTableName) WHERE remote_id = ?", arguments: [remoteID])
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createPageBookmarks") { db in
            try db.create(table: GRDBSyncedPageBookmark.databaseTableName, options: .ifNotExists) { table in
                table.column("page", .integer).notNull()
                table.column("remote_id", .text).primaryKey()
                table.column("creation_date", .datetime).notNull()
            }
        }
        return migrator
    }
}

private struct GRDBSyncedPageBookmark: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    enum CodingKeys: String, CodingKey {
        case page
        case creationDate = "creation_date"
        case remoteID = "remote_id"
    }

    static var databaseTableName: String {
        "synced_page_bookmarks"
    }

    var page: Int
    var creationDate: Date
    var remoteID: String

    var id: Int {
        page
    }
}

extension GRDBSyncedPageBookmark {
    init(_ bookmark: SyncedPageBookmarkPersistenceModel) {
        page = bookmark.page
        creationDate = bookmark.creationDate
        remoteID = bookmark.remoteID
    }

    func toPersistenceModel() -> SyncedPageBookmarkPersistenceModel {
        .init(page: page, remoteID: remoteID, creationDate: creationDate)
    }
}

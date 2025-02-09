//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 31/01/2025.
//

import Foundation
import Combine
import GRDB
import VLogging
import SQLitePersistence

// Rename this to SyncedPageBookmark?
public struct GRDBSyncedPageBookmarkPersistence {
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

    public func pageBookmarks() -> AnyPublisher<[SyncedPageBookmarkPersistenceModel], Never> {
        do {
            return try db.readPublisher { db in
                try GRDBSyncedPageBookmark.fetchAll(db).map{ $0.toPersistenceModel() }
            }
            .catch { error in
                logger.error("Error in page bookmarks publisher: \(error)")
                return Empty<[SyncedPageBookmarkPersistenceModel], Never>()
            }
            .eraseToAnyPublisher()
        }
        catch {
            logger.error("Failed to create a publisher for page bookmarks: \(error)")
            return Empty<[SyncedPageBookmarkPersistenceModel], Never>().eraseToAnyPublisher()
        }
    }

    func allPageBookmarks() async throws -> [SyncedPageBookmarkPersistenceModel] {
        try await db.read { db in
            try GRDBSyncedPageBookmark.fetchAll(db).map{ $0.toPersistenceModel() }
        }
    }

    public func insertPageBookmark(_ page: Int) async throws {
        try await db.write { db in
            var bookmark = GRDBSyncedPageBookmark(page: page)
            try bookmark.insert(db)
        }
    }
    
    public func removePageBookmark(_ page: Int) async throws {
        try await db.write { db in
            let bookmark = GRDBSyncedPageBookmark(page: page)
            try bookmark.delete(db)
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createPageBookmarks") { db in
            try db.create(table: GRDBSyncedPageBookmark.databaseTableName, options: .ifNotExists) { table in
                // Don't think we need a separate local id column.
                table.column("page", .integer).primaryKey()
                table.column("remote_id", .text)
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
    init(page: Int) {
        self.page = page
        self.creationDate = Date()
        self.remoteID = UUID().uuidString
    }

    func toPersistenceModel() -> SyncedPageBookmarkPersistenceModel {
        // TODO: Add remoteID to PageBookmarkPersistenceModel
        .init(page: page, remoteID: remoteID, creationDate: creationDate)
    }
}

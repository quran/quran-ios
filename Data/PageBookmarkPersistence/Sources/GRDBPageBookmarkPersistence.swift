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
public struct GRDBPageBookmarkPersistence {
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

    public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        do {
            return try db.readPublisher { db in
                try GRDBPageBookmark.fetchAll(db).map{ $0.toPersistenceModel() }
            }
            .catch { error in
                logger.error("Error in page bookmarks publisher: \(error)")
                return Empty<[PageBookmarkPersistenceModel], Never>()
            }
            .eraseToAnyPublisher()
        }
        catch {
            logger.error("Failed to create a publisher for page bookmarks: \(error)")
            return Empty<[PageBookmarkPersistenceModel], Never>().eraseToAnyPublisher()
        }
    }

    func allPageBookmarks() async throws -> [PageBookmarkPersistenceModel] {
        try await db.read { db in
            try GRDBPageBookmark.fetchAll(db).map{ $0.toPersistenceModel() }
        }
    }

    public func insertPageBookmark(_ page: Int) async throws {
        try await db.write { db in
            var bookmark = GRDBPageBookmark(page: page)
            try bookmark.insert(db)
        }
    }
    
    public func removePageBookmark(_ page: Int) async throws {
        try await db.write { db in
            let bookmark = GRDBPageBookmark(page: page)
            try bookmark.delete(db)
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createPageBookmarks") { db in
            try db.create(table: GRDBPageBookmark.databaseTableName, options: .ifNotExists) { table in
                // Don't think we need a separate local id column.
                table.column("page", .integer).primaryKey()
                table.column("remote_id", .text)
                table.column("creation_date", .datetime).notNull()
            }
        }
        return migrator
    }
}

private struct GRDBPageBookmark: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    enum CodingKeys: String, CodingKey {
        case page
        case creationDate = "creation_date"
        case remoteID = "remote_id"
    }
    static var databaseTableName: String {
        "page_bookmarks"
    }

    var page: Int
    var creationDate: Date
    var remoteID: String?

    var id: Int {
        page
    }
}

extension GRDBPageBookmark {
    init(page: Int) {
        self.page = page
        self.creationDate = Date()
    }

    func toPersistenceModel() -> PageBookmarkPersistenceModel {
        // TODO: Add remoteID to PageBookmarkPersistenceModel
        .init(page: page, creationDate: creationDate)
    }
}

//
//  GRDBDownloadsPersistence.swift
//  
//
//  Created by Mohamed Afifi on 2023-05-22.
//

import Foundation
import SQLitePersistence
import GRDB
import VLogging

struct GRDBDownloadsPersistence: DownloadsPersistence {
    let db: DatabaseWriter

    init(db: DatabaseWriter) {
        self.db = db
        do {
            try migrator.migrate(db)
        } catch {
            logger.error("Error while performing Translations migrations. Error: \(error)")
        }
    }

    init(filePath: String) {
        self.init(db: DatabasePool.newInstance(filePath: filePath))
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("Download and DownloadBatches") { db in
            try db.create(table: "grdbDownloadBatch", options: .ifNotExists) { table in
                table.autoIncrementedPrimaryKey("id")
            }

            try db.create(table: "grdbDownload", options: .ifNotExists) { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("downloadBatchId", .integer)
                    .notNull()
                    .indexed()
                    .references("grdbDownloadBatch", onDelete: .cascade)
                table.column("url", .text)
                    .notNull()
                    .indexed()
                table.column("resumePath", .text).notNull()
                table.column("destinationPath", .text).notNull()
                table.column("status", .integer).notNull()
                table.column("taskId", .integer)
            }
        }
        return migrator
    }

    func retrieveAll() async throws -> [DownloadBatch] {
        return try await db.read { db in
            let downloads = try GRDBDownload.fetchAll(db)
            let batches = Dictionary(grouping: downloads, by: { $0.downloadBatchId })
            return batches.map { DownloadBatch(id: $0, downloads: $1.map { $0.toDownload() }) }
        }
    }

    func insert(batch: DownloadBatchRequest) async throws -> DownloadBatch {
        try await db.write { db in
            var grdbBatch = GRDBDownloadBatch(id: nil)
            try grdbBatch.insert(db)
            let downloads = try batch.requests.map {
                var download = GRDBDownload(Download(taskId: nil, request: $0, status: .downloading, batchId: grdbBatch.id!))
                try download.insert(db)
                return download.toDownload()
            }
            return grdbBatch.toDownloadBatch(downloads: downloads)
        }
    }

    func update(downloads: [Download]) async throws {
        try await db.write { db in
            for download in downloads {
                let rows = GRDBDownload.filter(GRDBDownload.Columns.url == download.request.url)
                try rows.updateAll(db,
                                   GRDBDownload.Columns.status.set(to: download.status.rawValue),
                                   GRDBDownload.Columns.taskId.set(to: download.taskId))
            }
        }
    }

    func delete(batchIds: [Int64]) async throws {
        try await db.write { db in
            for batchId in batchIds {
                try GRDBDownloadBatch.filter(GRDBDownloadBatch.Columns.id == batchId).deleteAll(db)
            }
        }
    }
}

// MARK: - Database Model

private struct GRDBDownloadBatch: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?

    /// Updates the id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    static let downloads = hasMany(GRDBDownload.self)
}

extension GRDBDownloadBatch {
    func toDownloadBatch(downloads: [Download]) -> DownloadBatch {
        return DownloadBatch(id: id!, downloads: downloads)
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
    }
}

extension Download.Status: Codable, DatabaseValueConvertible { }

private struct GRDBDownload: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var downloadBatchId: Int64
    var url: URL
    var resumePath: String
    var destinationPath: String
    var status: Download.Status
    var taskId: Int?

    /// Updates the id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    static let downloadBatch = belongsTo(GRDBDownloadBatch.self)

    enum Columns {
        static let url = Column(CodingKeys.url)
        static let status = Column(CodingKeys.status)
        static let taskId = Column(CodingKeys.taskId)
    }
}

extension GRDBDownload {
    init(_ download: Download) {
        self.downloadBatchId = download.batchId
        self.url = download.request.url
        self.resumePath = download.request.resumePath
        self.destinationPath = download.request.destinationPath
        self.status = download.status
        self.taskId = download.taskId
    }

    func toDownload() -> Download {
        Download(taskId: taskId,
                 request: DownloadRequest(url: url, destinationPath: destinationPath),
                 status: status,
                 batchId: downloadBatchId)
    }
}

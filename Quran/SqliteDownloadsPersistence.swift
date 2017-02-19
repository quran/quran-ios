//
//  SqliteDownloadsPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/14/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import SQLite

extension Queue {
    static let downloads = Queue(queue: DispatchQueue(label: "com.quran.downloads"))
}

struct SqliteDownloadsPersistence: DownloadsPersistence, SQLitePersistence {

    let version: UInt = 1
    var filePath: String {
        return FileManager.default.documentsPath + "/downloads.db"
    }

    private struct Downloads {
        static let table = Table("download")
        static let id = Expression<Int64>("id")
        static let url = Expression<String>("url")
        static let resumePath = Expression<String>("resumePath")
        static let destinationPath = Expression<String>("destinationPath")
        static let status = Expression<Int>("status")
        static let batchId = Expression<Int64>("batchId")
    }

    private struct Batches {
        static let table = Table("batch")
        static let id = Expression<Int64>("id")
    }

    func onCreate(connection: Connection) throws {

        // batches table
        try connection.run(Batches.table.create { builder in
            builder.column(Batches.id, primaryKey: .autoincrement)
        })

        // downloads table
        try connection.run(Downloads.table.create { builder in
            builder.column(Downloads.id, primaryKey: .autoincrement)
            builder.column(Downloads.url)
            builder.column(Downloads.resumePath)
            builder.column(Downloads.destinationPath)
            builder.column(Downloads.status)
            builder.column(Downloads.batchId)
            builder.foreignKey(Downloads.batchId, references: Batches.table, Batches.id, update: .noAction, delete: .cascade)
        })
    }

    func retrieveAll() throws -> [DownloadBatch] {
        return try retrieve(nil)
    }

    func retrieve(status: Download.Status) throws -> [DownloadBatch] {
        return try retrieve(status)
    }

    private func retrieve(_ status: Download.Status?) throws -> [DownloadBatch] {
        return try run { connection in
            var query = Downloads.table.group(Downloads.batchId)
            if let status = status {
                query = query.filter(Downloads.status == status.rawValue)
            }
            let rows = try connection.prepare(query)
            let downloads = convert(rowsToDownloads: rows)
            return downloads
        }
    }

    func insert(batch: [Download]) throws -> [Download] {
        return try run { connection in
            // insert batch
            let batchInsert = Batches.table.insert()
            _ = try connection.run(batchInsert)
            guard let batchId = connection.lastInsertRowid else {
                return batch
            }

            // insert downloads
            for download in batch {
                let insert = Downloads.table.insert(
                    Downloads.url <- download.url.absoluteString,
                    Downloads.resumePath <- download.resumePath,
                    Downloads.destinationPath <- download.destinationPath,
                    Downloads.status <- Download.Status.downloading.rawValue,
                    Downloads.batchId <- batchId)

                _ = try connection.run(insert)
            }

            var downloads: [Download] = []
            for var download in batch {
                download.batchId = batchId
                downloads.append(download)
            }
            return downloads
        }
    }

    func update(url: URL, newStatus status: Download.Status) throws {
        return try update(filter: Downloads.url == url.absoluteString, newStatus: status)
    }

    func update(batches: [DownloadBatch], newStatus status: Download.Status) throws {
        let urls = batches.flatMap { $0.downloads.map { $0.url.absoluteString } }
        return try update(filter: urls.contains(Downloads.url), newStatus: status)
    }

    private func update(filter: Expression<Bool>, newStatus status: Download.Status) throws {
        return try run { connection in
            let rows = Downloads.table.filter(filter)
            let update = rows.update(Downloads.status <- status.rawValue)
            _ = try connection.run(update)
        }
    }

    private func convert(rowsToDownloads rows: AnySequence<Row>) -> [DownloadBatch] {
        var downloads: [Download] = []
        var batches: [DownloadBatch] = []
        var lastBatchId: Int64?
        for row in rows {
            if let download = convert(rowToDownload: row) {
                if download.batchId == lastBatchId {
                    downloads.append(download.download)
                } else {
                    if !downloads.isEmpty {
                        batches.append(DownloadBatch(downloads: downloads))
                        downloads.removeAll()
                    }
                }
                lastBatchId = download.batchId
            }
        }
        return batches
    }

    private func convert(rowToDownload row: Row) -> (download: Download, batchId: Int64)? {
        if let url = URL(string: row[Downloads.url]) {
            let resumePath = row[Downloads.resumePath]
            let destinationPath = row[Downloads.destinationPath]
            let status = Download.Status(rawValue: row[Downloads.status]) ?? .downloading
            let batchId = row[Downloads.batchId]
            let download = Download(url: url, resumePath: resumePath, destinationPath: destinationPath, status: status, batchId: batchId)
            return (download, batchId)
        }
        return nil
    }
}

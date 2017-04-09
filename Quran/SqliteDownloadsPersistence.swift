//
//  SqliteDownloadsPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/14/17.
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

struct SqliteDownloadsPersistence: DownloadsPersistence, SQLitePersistence {

    let version: UInt = 1
    var filePath: String {
        return Files.databasesPath.stringByAppendingPath("downloads.db")
    }

    private struct Downloads {
        static let table = Table("download")
        static let id = Expression<Int64>("id")
        static let taskId = Expression<Int>("taskId")
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
        try connection.run(Batches.table.create(ifNotExists: true) { builder in
            builder.column(Batches.id, primaryKey: .autoincrement)
        })

        // downloads table
        try connection.run(Downloads.table.create(ifNotExists: true) { builder in
            builder.column(Downloads.id, primaryKey: .autoincrement)
            builder.column(Downloads.taskId)
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
            var query = Downloads.table
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
            try connection.run(batchInsert)
            let batchId = connection.lastInsertRowid

            // insert downloads
            for download in batch {
                let taskId: Int = cast(download.taskId)
                let insert = Downloads.table.insert(
                    Downloads.taskId <- taskId,
                    Downloads.url <- download.url.absoluteString,
                    Downloads.resumePath <- download.resumePath,
                    Downloads.destinationPath <- download.destinationPath,
                    Downloads.status <- Download.Status.downloading.rawValue,
                    Downloads.batchId <- batchId)

                try connection.run(insert)
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

    func delete(batchId: Int64) throws {
        return try run { connection in
            let query = Downloads.table.filter(Downloads.batchId == batchId)
            let delete = query.delete()
            try connection.run(delete)
        }
    }

    private func update(filter: Expression<Bool>, newStatus status: Download.Status) throws {
        return try run { connection in
            let rows = Downloads.table.filter(filter)
            let update = rows.update(Downloads.status <- status.rawValue)
            try connection.run(update)
        }
    }

    private func convert(rowsToDownloads rows: AnySequence<Row>) -> [DownloadBatch] {
        let downloads = rows.flatMap { row in
            convert(rowToDownload: row)
        }

        let batches = downloads
            .group { $0.batchId }
            .map { DownloadBatch(downloads: $1.map { $0.download }) }

        return batches
    }

    private func convert(rowToDownload row: Row) -> (download: Download, batchId: Int64)? {
        if let url = URL(string: row[Downloads.url]) {
            let taskId = row[Downloads.taskId]
            let resumePath = row[Downloads.resumePath]
            let destinationPath = row[Downloads.destinationPath]
            let status = Download.Status(rawValue: row[Downloads.status]) ?? .downloading
            let batchId = row[Downloads.batchId]
            let download = Download(taskId: taskId,
                                    url: url,
                                    resumePath: resumePath,
                                    destinationPath: destinationPath,
                                    status: status,
                                    batchId: batchId)
            return (download, batchId)
        }
        return nil
    }
}

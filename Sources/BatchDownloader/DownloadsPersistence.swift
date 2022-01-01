//
//  DownloadsPersistence.swift
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
import SQLitePersistence
import Utilities

protocol DownloadsPersistence {
    func retrieveAll() throws -> [DownloadBatch]
    func insert(batch: DownloadBatchRequest) throws -> DownloadBatch
    func update(url: URL, newStatus status: Download.Status) throws
    func update(downloads: [Download]) throws
    func delete(batchIds: [Int64]) throws
}

final class SqliteDownloadsPersistence: DownloadsPersistence, SQLitePersistence {
    let version: UInt = 2
    let filePath: String

    private var connection: Connection?

    private struct Downloads {
        static let table = Table("download")
        static let id = Expression<Int64>("id")
        static let taskId = Expression<Int?>("taskId")
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

    init(filePath: String) {
        self.filePath = filePath
        connection = try? attempt(times: 3) { try openConnection() }
    }

    func onCreate(connection: Connection) throws {
        // batches table
        try connection.run(Batches.table.create(ifNotExists: true) { builder in
            builder.column(Batches.id, primaryKey: .autoincrement)
        })

        try createDownloadsTable(using: connection)
    }

    func onUpgrade(connection: Connection, oldVersion: UInt, newVersion: UInt) throws {
        if oldVersion < 2 {
            // We want to make taskId nullable, but it is not supported to drop NULL constraint
            // So we DROP and re-CREATE the table
            // we don't care about the data since user can re-download them again.

            try connection.run(Downloads.table.drop(ifExists: true))
            try createDownloadsTable(using: connection)
        }
    }

    private func createDownloadsTable(using connection: Connection) throws {
        // downloads table
        try connection.run(Downloads.table.create(ifNotExists: true) { builder in
            builder.column(Downloads.id, primaryKey: .autoincrement)
            builder.column(Downloads.taskId)
            builder.column(Downloads.url)
            builder.column(Downloads.resumePath)
            builder.column(Downloads.destinationPath)
            builder.column(Downloads.status)
            builder.column(Downloads.batchId)
            builder.foreignKey(Downloads.batchId, references: Batches.table, Batches.id)
        })
    }

    func retrieveAll() throws -> [DownloadBatch] {
        try run(using: connection) { connection in
            let query = Downloads.table
            let rows = try connection.prepare(query)
            let downloads = convert(rowsToDownloads: rows)
            return downloads
        }
    }

    func insert(batch: DownloadBatchRequest) throws -> DownloadBatch {
        try run(using: connection, inTransaction: true) { connection in
            // insert batch
            let batchInsert = Batches.table.insert()
            try connection.run(batchInsert)
            let batchId = connection.lastInsertRowid

            let columns = [Downloads.taskId.template,
                           Downloads.url.template,
                           Downloads.resumePath.template,
                           Downloads.destinationPath.template,
                           Downloads.status.template,
                           Downloads.batchId.template]

            // insert downloads multiple values at once
            let prefix = "INSERT INTO \"download\" (" + columns.joined(separator: ", ") + ") VALUES "
            let values: [String] = batch.requests.map { request -> String in
                let value = "(" +
                    "null," +
                    "'" + request.url.absoluteString + "'," +
                    "'" + request.resumePath + "'," +
                    "'" + request.destinationPath + "'," +
                    "\(Download.Status.pending.rawValue)," +
                    "\(batchId)" +
                    ")"
                return value
            }
            let statement = prefix + values.joined(separator: ",\n")
            try connection.run(statement)

            // prepare the result
            let downloads = batch.requests.map { Download(request: $0, batchId: batchId) }
            return DownloadBatch(id: batchId, downloads: downloads)
        }
    }

    func update(url: URL, newStatus status: Download.Status) throws {
        try run(using: connection) { connection in
            let rows = Downloads.table.filter(Downloads.url == url.absoluteString)
            let update = rows.update(
                Downloads.status <- status.rawValue)
            try connection.run(update)
        }
    }

    func update(downloads: [Download]) throws {
        try run(using: connection) { connection in
            for download in downloads {
                let rows = Downloads.table.filter(Downloads.url == download.request.url.absoluteString)
                let update = rows.update(
                    Downloads.status <- download.status.rawValue,
                    Downloads.taskId <- download.taskId
                )
                try connection.run(update)
            }
        }
    }

    func delete(batchIds: [Int64]) throws {
        try run(using: connection, inTransaction: true) { connection in
            let query1 = Downloads.table.filter(batchIds.contains(Downloads.batchId))
            let delete1 = query1.delete()
            try connection.run(delete1)

            let query2 = Batches.table.filter(batchIds.contains(Batches.id))
            let delete2 = query2.delete()
            try connection.run(delete2)
        }
    }

    private func convert(rowsToDownloads rows: AnySequence<Row>) -> [DownloadBatch] {
        let downloads = rows.map { convert(rowToDownload: $0) }

        let batches = downloads
            .group { $0.batchId }
            .map { DownloadBatch(id: $0, downloads: $1) }

        return batches
    }

    private func convert(rowToDownload row: Row) -> Download {
        let url = URL(validURL: row[Downloads.url])
        let taskId = row[Downloads.taskId]
        let destinationPath = row[Downloads.destinationPath]
        let status = Download.Status(rawValue: row[Downloads.status]) ?? .downloading
        let batchId = row[Downloads.batchId]

        let request = DownloadRequest(url: url, destinationPath: destinationPath)
        let download = Download(taskId: taskId, request: request, status: status, batchId: batchId)
        return download
    }
}

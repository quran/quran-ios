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
        return FileManager.default.documentsPath + "/bookmarks.db"
    }

    private struct Downloads {
        static let table = Table("download")
        static let url = Expression<String>("url")
        static let resumePath = Expression<String>("resumePath")
        static let destinationPath = Expression<String>("destinationPath")
    }

    func onCreate(connection: Connection) throws {
        // translations table
        try connection.run(Downloads.table.create { builder in
            builder.column(Downloads.url, primaryKey: true)
            builder.column(Downloads.resumePath)
            builder.column(Downloads.destinationPath)
        })
    }

    func retrieveAll() throws -> [Download] {
        return try run { connection in
            let query = Downloads.table
            let rows = try connection.prepare(query)
            let bookmarks = convert(rowsToDownloads: rows)
            return bookmarks
        }
    }

    func retrieve(urls: [URL]) throws -> [URL: Download] {
        let downloads: [Download] = try run { connection in
            let urlStrings = urls.map { $0.absoluteString }
            let query = Downloads.table.filter(urlStrings.contains(Downloads.url))
            let rows = try connection.prepare(query)
            let bookmarks = convert(rowsToDownloads: rows)
            return bookmarks
        }
        var dictionary: [URL: Download] = [:]
        downloads.forEach {
            dictionary[$0.url] = $0
        }
        return dictionary
    }

    func insert(downloads: [Download]) throws {
        return try run { connection in
            for download in downloads {
                let insert = Downloads.table.insert(
                    Downloads.url <- download.url.absoluteString,
                    Downloads.resumePath <- download.resumePath,
                    Downloads.destinationPath <- download.destinationPath)
                _ = try connection.run(insert)
            }
        }
    }

    func remove(url: URL) throws {
        return try run { connection in
            let filter = Downloads.table.filter(Downloads.url == url.absoluteString)
            _ = try connection.run(filter.delete())
        }
    }

    private func convert(rowsToDownloads rows: AnySequence<Row>) -> [Download] {
        var downloads: [Download] = []
        for row in rows {
            if let url = URL(string: row[Downloads.url]) {
                let resumePath = row[Downloads.resumePath]
                let destinationPath = row[Downloads.destinationPath]
                let download = Download(url: url, resumePath: resumePath, destinationPath: destinationPath)
                downloads.append(download)
            }
        }
        return downloads
    }
}

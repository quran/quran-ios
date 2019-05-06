//
//  SQLiteBookmarksPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
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

struct SQLiteBookmarksPersistence: BookmarksPersistence, SQLitePersistence {

    let version: UInt = 1
    var filePath: String {
        return FileManager.documentsPath.stringByAppendingPath("bookmarks.db")
    }

    private struct Bookmarks {
        static let table = Table("bookmark")
        static let id = Expression<Int>("_ID")
        static let sura = Expression<Int?>("sura")
        static let ayah = Expression<Int?>("ayah")
        static let page = Expression<Int>("page")
        static let creationDate = Expression<Date>("added_date")
    }

    private struct Tags {
        static let table = Table("tag")
        static let id = Expression<Int>("_ID")
        static let name = Expression<String>("name")
        static let creationDate = Expression<Date>("added_date")
    }

    private struct BookmarkTags {
        static let table = Table("bookmark_tag")
        static let id = Expression<Int>("_ID")
        static let bookmarkId = Expression<Int>("bookmark_id")
        static let tagId = Expression<Int>("tag_id")
        static let creationDate = Expression<Date>("added_date")
    }

    func onCreate(connection: Connection) throws {
        // bookmark table
        try connection.run(Bookmarks.table.create(ifNotExists: true) { builder in
            builder.column(Bookmarks.id, primaryKey: .autoincrement)
            builder.column(Bookmarks.sura)
            builder.column(Bookmarks.ayah)
            builder.column(Bookmarks.page)
            builder.column(Bookmarks.creationDate)
        })

        // tag table
        try connection.run(Tags.table.create(ifNotExists: true) { builder in
            builder.column(Tags.id, primaryKey: .autoincrement)
            builder.column(Tags.name)
            builder.column(Tags.creationDate)
        })

        // bookmark - tag
        try connection.run(BookmarkTags.table.create(ifNotExists: true) { builder in
            builder.column(BookmarkTags.id, primaryKey: .autoincrement)
            builder.column(BookmarkTags.bookmarkId)
            builder.column(BookmarkTags.tagId)
            builder.column(BookmarkTags.creationDate)
        })

        // page index
        try connection.run(Bookmarks.table.createIndex(Bookmarks.page, unique: false, ifNotExists: true))

        // (page - ayah - sura) index
        try connection.run(Bookmarks.table.createIndex(Bookmarks.page, Bookmarks.sura, Bookmarks.ayah, unique: true, ifNotExists: true))

        // (bookmark - tag) index
        try connection.run(BookmarkTags.table.createIndex(BookmarkTags.bookmarkId, BookmarkTags.tagId, unique: true, ifNotExists: true))
    }

    func retrieveAll() throws -> [Bookmark] {
        return try run { connection in
            let query = Bookmarks.table.order(Bookmarks.creationDate.desc)
            let rows = try connection.prepare(query)
            let bookmarks = convert(rowsToBookmarks: rows)
            return bookmarks
        }
    }

    func retrieve(inPage page: Int) throws -> [Bookmark] {
        return try run { connection in
            let query = Bookmarks.table.filter(Bookmarks.page == page)
            let rows = try connection.prepare(query)
            let bookmarks = convert(rowsToBookmarks: rows)
            return bookmarks
        }
    }

    func isAyahBookmarked(_ ayah: AyahNumber) throws -> Bool {
        return try run { connection in
            let query = Bookmarks.table.filter(
                Bookmarks.sura == ayah.sura &&
                Bookmarks.ayah == ayah.ayah)
            let rows = try connection.scalar(query.count)
            return rows > 0
        }
    }

    func insertPageBookmark(_ page: Int) throws {
        return try run { connection in

            let insert = Bookmarks.table.insert(
                Bookmarks.page <- page,
                Bookmarks.creationDate <- Date())
            try connection.run(insert)
        }
    }

    func insertAyahBookmark(_ ayah: AyahNumber) throws {
        return try run { connection in
            let insert = Bookmarks.table.insert(
                Bookmarks.sura <- ayah.sura,
                Bookmarks.ayah <- ayah.ayah,
                Bookmarks.page <- Quran.pageForAyah(ayah),
                Bookmarks.creationDate <- Date())
            try connection.run(insert)
        }
    }

    func removePageBookmark(_ page: Int) throws {
        return try run { connection in
            let filter = Bookmarks.table.filter(
                Bookmarks.page == page &&
                Bookmarks.sura == nil &&
                Bookmarks.ayah == nil)
            try connection.run(filter.delete())
        }
    }

    func removeAyahBookmark(_ ayah: AyahNumber) throws {
        return try run { connection in

            let filter = Bookmarks.table.filter(
                Bookmarks.sura == ayah.sura &&
                Bookmarks.ayah == ayah.ayah)
            try connection.run(filter.delete())
        }
    }

    private func convert(rowsToBookmarks rows: AnySequence<Row>) -> [Bookmark] {
        var bookmarks: [Bookmark] = []
        for row in rows {
            let page = row[Bookmarks.page]
            let creationDate = row[Bookmarks.creationDate]
            let tags: [Tag] = []
            let bookmark: Bookmark
            if let ayah = row[Bookmarks.ayah], let sura = row[Bookmarks.sura] {
                bookmark = AyahBookmark(ayah: AyahNumber(sura: sura, ayah: ayah), page: page, creationDate: creationDate, tags: tags)
            } else {
                bookmark = PageBookmark(page: page, creationDate: creationDate, tags: tags)
            }
            bookmarks.append(bookmark)
        }
        return bookmarks
    }
}

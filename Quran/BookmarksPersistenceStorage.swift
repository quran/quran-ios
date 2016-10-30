//
//  BookmarksPersistenceStorage.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import SQLite

struct BookmarksPersistenceStorage: BookmarksPersistence, SqlitePersistence {

    let version: UInt = 1
    var filePath: String {
        return FileManager.default.documentsPath + "/bookmarks.db"
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
        print("afifi", connection.description)

        // bookmark table
        try connection.run(Bookmarks.table.create { builder in
            builder.column(Bookmarks.id, primaryKey: .autoincrement)
            builder.column(Bookmarks.sura)
            builder.column(Bookmarks.ayah)
            builder.column(Bookmarks.page)
            builder.column(Bookmarks.creationDate)
        })

        // tag table
        try connection.run(Tags.table.create { builder in
            builder.column(Tags.id, primaryKey: .autoincrement)
            builder.column(Tags.name)
            builder.column(Tags.creationDate)
        })

        // bookmark - tag
        try connection.run(BookmarkTags.table.create { builder in
            builder.column(BookmarkTags.id, primaryKey: .autoincrement)
            builder.column(BookmarkTags.bookmarkId)
            builder.column(BookmarkTags.tagId)
            builder.column(BookmarkTags.creationDate)
        })

        // page index
        try connection.run(Bookmarks.table.createIndex([Bookmarks.page], unique: false))

        // (page - ayah - sura) index
        try connection.run(Bookmarks.table.createIndex([Bookmarks.page, Bookmarks.sura, Bookmarks.ayah], unique: true))

        // (bookmark - tag) index
        try connection.run(BookmarkTags.table.createIndex([BookmarkTags.bookmarkId, BookmarkTags.tagId], unique: true))
    }

    func retrieveAll() -> [Bookmark] {
        return run { connection in
            let query = Bookmarks.table.order(Bookmarks.creationDate)
            let rows = try connection.prepare(query)
            let bookmarks = convert(rowsToBookmarks: rows)
            return bookmarks
        }
    }

    func retrieve(inPage page: Int) -> [Bookmark] {
        return run { connection in
            let query = Bookmarks.table.filter(Bookmarks.page == page)
            let rows = try connection.prepare(query)
            let bookmarks = convert(rowsToBookmarks: rows)
            return bookmarks
        }
    }

    func insert(_ bookmark: Bookmark) {
        return run { connection in

            let ayah = (bookmark as? AyahBookmark)?.ayah

            let insert = Bookmarks.table.insert(
                Bookmarks.sura <- ayah?.sura,
                Bookmarks.ayah <- ayah?.ayah,
                Bookmarks.page <- bookmark.page,
                Bookmarks.creationDate <- bookmark.creationDate)
            _ = try connection.run(insert)
        }
    }

    func remove(_ bookmark: Bookmark) {

        return run { connection in

            let ayah = (bookmark as? AyahBookmark)?.ayah

            let filter = Bookmarks.table.filter(
                Bookmarks.sura == ayah?.sura &&
                Bookmarks.ayah == ayah?.ayah &&
                Bookmarks.page == bookmark.page)
            _ = try connection.run(filter.delete())
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

//
//  BookmarksPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol BookmarksPersistence {
    func retrieveAll() throws -> [Bookmark]
    func retrieve(inPage page: Int) throws -> [Bookmark]
    func insert(_ bookmark: Bookmark) throws
    func remove(_ bookmark: Bookmark) throws
}

extension BookmarksPersistence {

    func retrieveAll() throws -> ([PageBookmark], [AyahBookmark]) {
        return split(bookmarks: try retrieveAll())
    }

    func retrievePageBookmarks() throws -> [PageBookmark] {
        return try retrieveAll().0
    }

    func retrieveAyahBookmarks() throws -> [AyahBookmark] {
        return try retrieveAll().1
    }

    func retrieve(inPage page: Int) throws -> ([PageBookmark], [AyahBookmark]) {
        return split(bookmarks: try retrieve(inPage: page))
    }

    func isPageBookmarked(_ page: Int) -> Bool {
        return !((try? retrieve(inPage: page))?.0.isEmpty ?? true)
    }

    func removePageBookmark(atPage page: Int) throws {
        try remove(PageBookmark(page: page, creationDate: Date(), tags: []))
    }

    func insertPageBookmark(forPage page: Int) throws {
        try insert(PageBookmark(page: page, creationDate: Date(), tags: []))
    }

    func removeAyahBookmark(atPage page: Int, ayah: AyahNumber) throws {
        try remove(AyahBookmark(ayah: ayah, page: page, creationDate: Date(), tags: []))
    }

    func insertAyahBookmark(forPage page: Int, ayah: AyahNumber) throws {
        try insert(AyahBookmark(ayah: ayah, page: page, creationDate: Date(), tags: []))
    }

    private func split(bookmarks: [Bookmark]) -> ([PageBookmark], [AyahBookmark]) {
        var pageBookmarks: [PageBookmark] = []
        var ayahBookmarks: [AyahBookmark] = []
        bookmarks.forEach { bookmark in
            if let pageBookmark = bookmark as? PageBookmark {
                pageBookmarks.append(pageBookmark)
            } else if let ayahBookmark = bookmark as? AyahBookmark {
                ayahBookmarks.append(ayahBookmark)
            }
        }
        return (pageBookmarks, ayahBookmarks)
    }
}

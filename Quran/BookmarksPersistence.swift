//
//  BookmarksPersistence.swift
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

protocol BookmarksPersistence {
    func retrieveAll() throws -> [Bookmark]
    func retrieve(inPage page: Int) throws -> [Bookmark]
    func isAyahBookmarked(_ ayah: AyahNumber) throws -> Bool

    func insertPageBookmark(_ page: Int) throws
    func insertAyahBookmark(_ ayah: AyahNumber) throws

    func removePageBookmark(_ page: Int) throws
    func removeAyahBookmark(_ ayah: AyahNumber) throws
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

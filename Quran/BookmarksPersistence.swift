//
//  BookmarksPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol BookmarksPersistence {
    func retrieveAll() -> [Bookmark]
    func retrieve(inPage page: Int) -> [Bookmark]
    func insert(_ bookmark: Bookmark)
    func remove(_ bookmark: Bookmark)
}

extension BookmarksPersistence {

    func retrieveAll() -> ([PageBookmark], [AyahBookmark]) {
        return split(bookmarks: retrieveAll())
    }

    func retrieve(inPage page: Int) -> ([PageBookmark], [AyahBookmark]) {
        return split(bookmarks: retrieve(inPage: page))
    }

    func isPageBookmarked(_ page: Int) -> Bool {
        return !retrieve(inPage: page).0.isEmpty
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

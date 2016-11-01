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

    func retrievePageBookmarks() -> [PageBookmark] {
        return retrieveAll().0
    }

    func retrieveAyahBookmarks() -> [AyahBookmark] {
        return retrieveAll().1
    }

    func retrieve(inPage page: Int) -> ([PageBookmark], [AyahBookmark]) {
        return split(bookmarks: retrieve(inPage: page))
    }

    func isPageBookmarked(_ page: Int) -> Bool {
        return !retrieve(inPage: page).0.isEmpty
    }

    func removePageBookmark(atPage page: Int) {
        remove(PageBookmark(page: page, creationDate: Date(), tags: []))
    }

    func insertPageBookmark(forPage page: Int) {
        insert(PageBookmark(page: page, creationDate: Date(), tags: []))
    }

    func removeAyahBookmark(atPage page: Int, ayah: AyahNumber) {
        remove(AyahBookmark(ayah: ayah, page: page, creationDate: Date(), tags: []))
    }

    func insertAyahBookmark(forPage page: Int, ayah: AyahNumber) {
        insert(AyahBookmark(ayah: ayah, page: page, creationDate: Date(), tags: []))
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

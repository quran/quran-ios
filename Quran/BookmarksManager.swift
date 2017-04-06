//
//  BookmarksManager.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import PromiseKit

class BookmarksManager {
    private let bookmarksPersistence: BookmarksPersistence
    init(bookmarksPersistence: BookmarksPersistence) {
        self.bookmarksPersistence = bookmarksPersistence
    }

    private(set) var isBookmarked: Bool = false

    func calculateIsBookmarked(pageNumber: Int) -> Promise<Bool> {
        return DispatchQueue.global()
            .promise { self.bookmarksPersistence.isPageBookmarked(pageNumber) }
            .then(on: .main) { bookmarked -> Bool in
                self.isBookmarked = bookmarked
                return bookmarked
        }
    }

    func toggleBookmarking(pageNumber: Int) -> Promise<Void> {
        isBookmarked = !isBookmarked

        if isBookmarked {
            return DispatchQueue.global() .promise {
                try self.bookmarksPersistence.insertPageBookmark(forPage: pageNumber)
            }
        } else {
            return DispatchQueue.global() .promise {
                try self.bookmarksPersistence.removePageBookmark(atPage: pageNumber)
            }
        }
    }
}

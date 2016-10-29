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
    func retrieve(inPage: Int) -> [Bookmark]
    func insert(_ bookmark: Bookmark)
    func remove(_ bookmark: Bookmark)
}

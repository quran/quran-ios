//
//  PageBookmarkPersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Combine

public protocol PageBookmarkPersistence {
    func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never>
    func insertPageBookmark(_ page: Int) async throws
    func removePageBookmark(_ page: Int) async throws
}

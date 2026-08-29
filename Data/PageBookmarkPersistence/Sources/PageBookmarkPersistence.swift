//
//  PageBookmarkPersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Combine
import QuranKit

public protocol PageBookmarkPersistence {
    func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never>
    func insertPageBookmark(at page: Page) async throws
    func removePageBookmarks(at pages: Set<Page>) async throws
    func removeAllPageBookmarks() async throws
}

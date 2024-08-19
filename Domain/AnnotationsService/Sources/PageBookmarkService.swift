//
//  PageBookmarkService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Combine
import PageBookmarkPersistence
import QuranAnnotations
import QuranKit

public struct PageBookmarkService {
    // MARK: Lifecycle

    public init(persistence: PageBookmarkPersistence) {
        self.persistence = persistence
    }

    // MARK: Public

    public func pageBookmarks(quran: Quran) -> AnyPublisher<[PageBookmark], Never> {
        persistence.pageBookmarks()
            .map { bookmarks in bookmarks.map { PageBookmark(quran: quran, $0) } }
            .eraseToAnyPublisher()
    }

    public func insertPageBookmark(_ page: Page) async throws {
        try await persistence.insertPageBookmark(page.pageNumber)
    }

    public func removePageBookmark(_ page: Page) async throws {
        try await persistence.removePageBookmark(page.pageNumber)
    }

    // MARK: Internal

    let persistence: PageBookmarkPersistence
}

private extension PageBookmark {
    init(quran: Quran, _ other: PageBookmarkPersistenceModel) {
        self.init(
            page: Page(quran: quran, pageNumber: Int(other.page))!,
            creationDate: other.creationDate
        )
    }
}

//
//  PageBookmarkService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Combine
import Foundation
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
        let mapper = QuranPageMapper(destination: quran)
        return persistence.pageBookmarks()
            .map { bookmarks in
                let mappedBookmarks = bookmarks.compactMap { bookmark -> MappedBookmark? in
                    guard let presentationPage = mapper.mapPage(bookmark.page) else {
                        return nil
                    }
                    return MappedBookmark(
                        presentationPage: presentationPage,
                        storedPage: bookmark.page,
                        creationDate: bookmark.creationDate
                    )
                }

                return Dictionary(grouping: mappedBookmarks, by: \.presentationPage)
                    .values
                    .compactMap { groupedBookmarks -> PageBookmark? in
                        guard let newestBookmark = groupedBookmarks.max(by: {
                            $0.creationDate < $1.creationDate
                        }) else {
                            return nil
                        }
                        return PageBookmark(
                            page: newestBookmark.presentationPage,
                            storedPages: Set(groupedBookmarks.map(\.storedPage)),
                            creationDate: newestBookmark.creationDate
                        )
                    }
                    .sorted { $0.creationDate > $1.creationDate }
            }
            .eraseToAnyPublisher()
    }

    public func insertPageBookmark(_ page: Page) async throws {
        try await persistence.insertPageBookmark(at: page)
    }

    public func removePageBookmark(_ bookmark: PageBookmark) async throws {
        try await persistence.removePageBookmarks(at: bookmark.storedPages)
    }

    public func removeAllPageBookmarks() async throws {
        try await persistence.removeAllPageBookmarks()
    }

    // MARK: Internal

    let persistence: PageBookmarkPersistence
}

private struct MappedBookmark {
    let presentationPage: Page
    let storedPage: Page
    let creationDate: Date
}

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

    public init(persistence: PageBookmarkPersistence, storedPageQuran: Quran = .hafsMadani1405) {
        self.persistence = persistence
        self.storedPageQuran = storedPageQuran
    }

    // MARK: Public

    public func pageBookmarks(quran: Quran) -> AnyPublisher<[PageBookmark], Never> {
        let mapper = QuranPageMapper(destination: quran)
        return persistence.pageBookmarks()
            .map { bookmarks in
                bookmarks.compactMap { bookmark in
                    Page(quran: storedPageQuran, pageNumber: bookmark.page)
                        .flatMap(mapper.mapPage)
                        .map {
                            PageBookmark(page: $0, creationDate: bookmark.creationDate)
                        }
                }
            }
            .eraseToAnyPublisher()
    }

    public func insertPageBookmark(_ page: Page) async throws {
        let storedPage = try storedPage(for: page)
        try await persistence.insertPageBookmark(storedPage.pageNumber)
    }

    public func removePageBookmark(_ page: Page) async throws {
        let storedPage = try storedPage(for: page)
        try await persistence.removePageBookmark(storedPage.pageNumber)
    }

    public func removeAllPageBookmarks() async throws {
        try await persistence.removeAllPageBookmarks()
    }

    // MARK: Internal

    let persistence: PageBookmarkPersistence
    let storedPageQuran: Quran

    // MARK: Private

    private func storedPage(for page: Page) throws -> Page {
        guard let storedPage = QuranPageMapper(destination: storedPageQuran).mapPage(page) else {
            throw PageMappingError.unableToMapPage(
                pageNumber: page.pageNumber,
                source: page.quran,
                destination: storedPageQuran
            )
        }

        return storedPage
    }
}

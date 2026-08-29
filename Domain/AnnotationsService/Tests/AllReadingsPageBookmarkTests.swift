//
//  AllReadingsPageBookmarkTests.swift
//  Quran
//

import Combine
import XCTest
@testable import AnnotationsService
@testable import QuranKit

@MainActor
final class AllReadingsPageBookmarkTests: XCTestCase {
    func testEveryPageFromEveryReadingCanBePresentedAndRemovedInEveryReading() async throws {
        for sourceReading in Reading.allReadings {
            let sourcePersistence = PageBookmarkPersistenceFake()
            let sourceService = PageBookmarkService(persistence: sourcePersistence)

            for sourcePage in sourceReading.quran.pages {
                try await sourceService.insertPageBookmark(sourcePage)
            }

            let storedBookmarks = sourcePersistence.bookmarks
            let expectedPages = Set(storedBookmarks.map(\.page))
            XCTAssertEqual(
                expectedPages.count,
                sourceReading.quran.pages.count,
                "Every \(sourceReading) page should be stored uniquely"
            )

            for destinationReading in Reading.allReadings {
                let context = "\(sourceReading) → \(destinationReading)"
                let persistence = PageBookmarkPersistenceFake(bookmarks: storedBookmarks)
                let service = PageBookmarkService(persistence: persistence)
                let presentedBookmarks = value(
                    from: service.pageBookmarks(quran: destinationReading.quran)
                )
                let presentedStoredPages = presentedBookmarks.flatMap(\.storedPages)

                XCTAssertEqual(Set(presentedStoredPages), expectedPages, context)
                XCTAssertEqual(presentedStoredPages.count, expectedPages.count, context)
                XCTAssertEqual(
                    Set(presentedBookmarks.map(\.page)).count,
                    presentedBookmarks.count,
                    context
                )
                XCTAssertTrue(
                    presentedBookmarks.allSatisfy {
                        $0.page.quran == destinationReading.quran
                    },
                    context
                )

                for bookmark in presentedBookmarks {
                    try await service.removePageBookmark(bookmark)
                }

                XCTAssertTrue(persistence.bookmarks.isEmpty, context)
            }
        }
    }

    // MARK: Private

    private func value<P: Publisher>(from publisher: P) -> P.Output where P.Failure == Never {
        var value: P.Output?
        let cancellable = publisher.sink { value = $0 }
        withExtendedLifetime(cancellable) {}
        return value!
    }
}

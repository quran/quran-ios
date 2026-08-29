//
//  AllReadingsLastPageTests.swift
//  Quran
//

#if !QURAN_SYNC
import XCTest
@testable import AnnotationsService
@testable import QuranKit

@MainActor
final class AllReadingsLastPageTests: XCTestCase {
    func testEveryLastPageFromEveryReadingCanBePresentedInEveryReading() async throws {
        for sourceReading in Reading.allReadings {
            let sourcePersistence = LastPagePersistenceFake()
            let sourceService = PersistenceLastPageService(persistence: sourcePersistence)

            for sourcePage in sourceReading.quran.pages {
                _ = try await sourceService.add(page: sourcePage)
            }

            let storedLastPages = sourcePersistence.lastPagesList
            let expectedPages = Set(storedLastPages.map(\.page))
            XCTAssertEqual(
                expectedPages.count,
                sourceReading.quran.pages.count,
                "Every \(sourceReading) page should be stored uniquely"
            )

            for destinationReading in Reading.allReadings {
                let context = "\(sourceReading) → \(destinationReading)"
                let persistence = LastPagePersistenceFake(lastPages: storedLastPages)
                let service = PersistenceLastPageService(persistence: persistence)
                var iterator = service.lastPages(quran: destinationReading.quran).makeAsyncIterator()
                let nextLastPages = try await iterator.next()
                let presentedLastPages = try XCTUnwrap(nextLastPages, context)
                let presentedStoredPages = presentedLastPages.flatMap(\.storedPages)

                XCTAssertEqual(Set(presentedStoredPages), expectedPages, context)
                XCTAssertEqual(presentedStoredPages.count, expectedPages.count, context)
                XCTAssertEqual(
                    Set(presentedLastPages.map(\.page)).count,
                    presentedLastPages.count,
                    context
                )
                XCTAssertTrue(
                    presentedLastPages.allSatisfy {
                        $0.page.quran == destinationReading.quran
                    },
                    context
                )
            }
        }
    }
}
#endif

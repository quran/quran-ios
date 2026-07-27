#if !QURAN_SYNC
import Analytics
import AnnotationsService
import Combine
import Foundation
import PageBookmarkPersistence
import QuranAnnotations
import QuranKit
import XCTest
@testable import BookmarksFeature

@MainActor
final class BookmarksViewModelTests: XCTestCase {
    // MARK: Internal

    func test_deleteItem_removesBookmarkPage() async {
        let persistence = PageBookmarkPersistenceSpy()
        let sut = makeSUT(persistence: persistence)
        let bookmark = PageBookmark(page: Quran.hafsMadani1405.pages[0], creationDate: Date())

        await sut.deleteItem(bookmark)

        XCTAssertEqual(persistence.removedPages, [bookmark.page.pageNumber])
        XCTAssertNil(sut.error)
    }

    func test_navigateToBookmark_navigatesToPage() {
        let page = Quran.hafsMadani1405.pages[269]
        let bookmark = PageBookmark(page: page, creationDate: .distantPast)
        var navigatedPage: Page?
        let sut = makeSUT(navigateTo: { navigatedPage = $0 })

        sut.navigateTo(bookmark)

        XCTAssertEqual(navigatedPage, page)
    }

    // MARK: Private

    private func makeSUT(
        persistence: PageBookmarkPersistenceSpy = PageBookmarkPersistenceSpy(),
        navigateTo: @escaping (Page) -> Void = { _ in }
    ) -> BookmarksViewModel {
        let service = PageBookmarkService(persistence: persistence)
        return BookmarksViewModel(
            analytics: AnalyticsSpy(),
            service: service,
            navigateTo: navigateTo
        )
    }
}

private struct AnalyticsSpy: AnalyticsLibrary {
    func logEvent(_: String, value _: String) {}
}

private final class PageBookmarkPersistenceSpy: PageBookmarkPersistence {
    var removedPages: [Int] = []

    func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func insertPageBookmark(_: Int) async throws {}
    func removePageBookmark(_ page: Int) async throws {
        removedPages.append(page)
    }

    func removeAllPageBookmarks() async throws {}
}
#endif

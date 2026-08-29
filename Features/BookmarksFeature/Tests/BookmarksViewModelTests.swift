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

    func test_deleteItem_removesBookmarkPage() async throws {
        let persistence = PageBookmarkPersistenceSpy()
        let sut = makeSUT(persistence: persistence)
        let bookmark = PageBookmark(page: Quran.hafsMadani1405.pages[0], creationDate: Date())
        sut.bookmarks = [bookmark]

        let operation = try XCTUnwrap(sut.deleteItem(bookmark))

        XCTAssertTrue(sut.bookmarks.isEmpty)
        await operation()
        XCTAssertEqual(persistence.removedPages, [bookmark.page])
        XCTAssertNil(sut.error)
    }

    func test_deleteItem_ignoresDuplicateRequestWhileDeletionIsInProgress() async throws {
        let persistence = PageBookmarkPersistenceSpy()
        persistence.suspendRemoval = true
        let sut = makeSUT(persistence: persistence)
        let bookmark = PageBookmark(page: Quran.hafsMadani1405.pages[0], creationDate: Date())
        sut.bookmarks = [bookmark]

        let operation = try XCTUnwrap(sut.deleteItem(bookmark))
        let duplicateOperation = sut.deleteItem(bookmark)
        let task = Task { await operation() }
        await fulfillment(of: [persistence.removeExpectation])

        XCTAssertNil(duplicateOperation)
        XCTAssertEqual(persistence.removedPages, [bookmark.page])
        persistence.resumeRemoval()
        await task.value
    }

    func test_deleteItem_restoresBookmarkWhenPersistenceFails() async throws {
        let persistence = PageBookmarkPersistenceSpy()
        persistence.removeError = TestError.expected
        let sut = makeSUT(persistence: persistence)
        let bookmark = PageBookmark(page: Quran.hafsMadani1405.pages[0], creationDate: Date())
        sut.bookmarks = [bookmark]

        let operation = try XCTUnwrap(sut.deleteItem(bookmark))
        XCTAssertTrue(sut.bookmarks.isEmpty)

        await operation()

        XCTAssertEqual(sut.bookmarks, [bookmark])
        XCTAssertNotNil(sut.error)
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
    let removeExpectation = XCTestExpectation(description: "Remove bookmark")
    var removedPages: [Page] = []
    var removeError: Error?
    var suspendRemoval = false

    private var removalContinuation: CheckedContinuation<Void, Never>?

    func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func insertPageBookmark(at _: Page) async throws {}
    func removePageBookmarks(at pages: Set<Page>) async throws {
        removedPages.append(contentsOf: pages)
        removeExpectation.fulfill()
        if let removeError {
            throw removeError
        }
        if suspendRemoval {
            await withCheckedContinuation { removalContinuation = $0 }
        }
    }

    func removeAllPageBookmarks() async throws {}

    func resumeRemoval() {
        removalContinuation?.resume()
        removalContinuation = nil
    }
}

private enum TestError: Error {
    case expected
}
#endif

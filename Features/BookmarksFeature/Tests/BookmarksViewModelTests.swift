import Analytics
import AnnotationsService
#if QURAN_SYNC
import AuthenticationClient
import AuthenticationClientFake
#endif
import Combine
import Foundation
import PageBookmarkPersistence
import QuranAnnotations
import QuranKit
#if QURAN_SYNC
import UIKit
#endif
import XCTest
@testable import BookmarksFeature

@MainActor
final class BookmarksViewModelTests: XCTestCase {
    // MARK: Internal

    #if QURAN_SYNC
    override func setUp() {
        super.setUp()
        BookmarksPreferences.shared.isSyncBannerDismissed = false
    }

    override func tearDown() {
        BookmarksPreferences.shared.isSyncBannerDismissed = false
        super.tearDown()
    }
    #endif

    func test_deleteItem_removesBookmarkPage() async {
        let persistence = PageBookmarkPersistenceSpy()
        let sut = makeSUT(persistence: persistence)
        let bookmark = PageBookmark(page: Quran.hafsMadani1405.pages[0], creationDate: Date())

        await sut.deleteItem(bookmark)

        XCTAssertEqual(persistence.removedPages, [bookmark.page.pageNumber])
        XCTAssertNil(sut.error)
    }

    #if QURAN_SYNC
    func test_start_setsAuthenticatedState_whenRestoreSucceeds() async {
        let client = AuthenticationClientFake()
        client.restoreStateResult = .success(.authenticated)
        let sut = makeSyncSUT(authenticationClient: client)

        let task = Task { await sut.start() }
        await waitUntil { sut.isAuthenticated }
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(client.events, [.restoreState])
        task.cancel()
    }

    func test_start_fallsBackToCurrentState_whenRestoreFails() async {
        let client = AuthenticationClientFake()
        client.restoreStateResult = .failure(.clientIsNotAuthenticated(NSError(domain: "test", code: 1)))
        client.authenticationStateValue = .authenticated
        let sut = makeSyncSUT(authenticationClient: client)

        let task = Task { await sut.start() }
        await waitUntil { sut.isAuthenticated }
        XCTAssertEqual(client.events, [.restoreState, .readAuthenticationState])
        task.cancel()
    }

    func test_loginToQuranCom_setsAuthenticated_whenLoginSucceeds() async {
        let client = AuthenticationClientFake()
        let sut = makeSyncSUT(authenticationClient: client)
        let presenter = UIViewController()
        sut.presenter = presenter

        await sut.loginToQuranCom()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(client.events, [.login])
        XCTAssertNil(sut.error)
    }

    func test_loginToQuranCom_setsError_whenClientIsMissing() async {
        let sut = makeSyncSUT(authenticationClient: nil)
        let presenter = UIViewController()
        sut.presenter = presenter

        await sut.loginToQuranCom()

        guard case .clientIsNotAuthenticated = sut.error as? AuthenticationClientError else {
            return XCTFail("Expected clientIsNotAuthenticated, got \(String(describing: sut.error))")
        }
    }
    #endif

    // MARK: Private

    private func makeSUT(persistence: PageBookmarkPersistenceSpy = PageBookmarkPersistenceSpy()) -> BookmarksViewModel {
        let service = PageBookmarkService(persistence: persistence)
        #if QURAN_SYNC
        return BookmarksViewModel(
            analytics: AnalyticsSpy(),
            service: service,
            authenticationClient: UnavailableAuthenticationClient(),
            navigateTo: { _ in }
        )
        #else
        return BookmarksViewModel(
            analytics: AnalyticsSpy(),
            service: service,
            navigateTo: { _ in }
        )
        #endif
    }

    #if QURAN_SYNC
    private func makeSyncSUT(authenticationClient: (any AuthenticationClient)?) -> BookmarksViewModel {
        let service = PageBookmarkService(persistence: PageBookmarkPersistenceSpy())
        return BookmarksViewModel(
            analytics: AnalyticsSpy(),
            service: service,
            authenticationClient: authenticationClient,
            navigateTo: { _ in }
        )
    }

    private func waitUntil(
        timeoutIterations: Int = 100,
        condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0 ..< timeoutIterations {
            if condition() {
                return
            }
            await Task.yield()
        }
        XCTFail("Condition was not met in time", file: file, line: line)
    }
    #endif
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

import Analytics
import AnnotationsService
import AuthenticationClient
import AuthenticationClientFake
import Combine
import Foundation
import PageBookmarkPersistence
import UIKit
import XCTest
@testable import BookmarksFeature

@MainActor
final class BookmarksViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        BookmarksPreferences.shared.isSyncBannerDismissed = false
    }

    override func tearDown() {
        BookmarksPreferences.shared.isSyncBannerDismissed = false
        super.tearDown()
    }

    func test_start_setsAuthenticatedState_whenRestoreSucceeds() async {
        let client = AuthenticationClientFake()
        client.restoreStateResult = .success(.authenticated)
        let sut = makeSUT(authenticationClient: client)

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
        let sut = makeSUT(authenticationClient: client)

        let task = Task { await sut.start() }
        await waitUntil { sut.isAuthenticated }
        XCTAssertEqual(client.events, [.restoreState, .readAuthenticationState])
        task.cancel()
    }

    func test_loginToQuranCom_setsAuthenticated_whenLoginSucceeds() async {
        let client = AuthenticationClientFake()
        let sut = makeSUT(authenticationClient: client)
        let presenter = UIViewController()
        sut.presenter = presenter

        await sut.loginToQuranCom()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(client.events, [.login])
        XCTAssertNil(sut.error)
    }

    func test_loginToQuranCom_setsError_whenClientIsMissing() async {
        let sut = makeSUT(authenticationClient: nil)
        let presenter = UIViewController()
        sut.presenter = presenter

        await sut.loginToQuranCom()

        guard case .clientIsNotAuthenticated = sut.error as? AuthenticationClientError else {
            return XCTFail("Expected clientIsNotAuthenticated, got \(String(describing: sut.error))")
        }
    }

    // MARK: Private

    private func makeSUT(authenticationClient: (any AuthenticationClient)?) -> BookmarksViewModel {
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
}

private struct AnalyticsSpy: AnalyticsLibrary {
    func logEvent(_: String, value _: String) {}
}

private struct PageBookmarkPersistenceSpy: PageBookmarkPersistence {
    func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func insertPageBookmark(_: Int) async throws {}
    func removePageBookmark(_: Int) async throws {}
    func removeAllPageBookmarks() async throws {}
}

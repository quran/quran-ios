import Analytics
import AppDependencies
import AudioDownloadsFeature
import AuthenticationClient
import BatchDownloader
import Foundation
import LastPagePersistence
import NotePersistence
import PageBookmarkPersistence
import ReadingSelectorFeature
import ReadingService
import SettingsService
import TranslationsFeature
import UIKit
import XCTest
@testable import SettingsFeature

@MainActor
final class SettingsRootViewModelTests: XCTestCase {
    // MARK: Internal

    func test_refreshAuthenticationState_returnsNotAuthenticated_whenClientIsMissing() async {
        let sut = makeSUT(authenticationClient: nil)

        await sut.refreshAuthenticationState()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserEmail)
    }

    func test_refreshAuthenticationState_returnsRestoredState_whenRestoreSucceeds() async {
        let client = AuthenticationClientSpy()
        client.restoreStateResult = .authenticated
        client.loggedInUserValue = makeUser(email: "user@example.com")
        let sut = makeSUT(authenticationClient: client)

        await sut.refreshAuthenticationState()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUserEmail, "user@example.com")
        XCTAssertEqual(client.restoreStateCallCount, 1)
        XCTAssertEqual(client.authenticationStateReads, 0)
    }

    func test_refreshAuthenticationState_fallsBackToCurrentState_whenRestoreFails() async {
        let client = AuthenticationClientSpy()
        client.restoreStateError = NSError(domain: "test", code: 1)
        client.authenticationStateValue = .authenticated
        client.loggedInUserValue = makeUser(email: "user@example.com")
        let sut = makeSUT(authenticationClient: client)

        await sut.refreshAuthenticationState()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUserEmail, "user@example.com")
        XCTAssertEqual(client.restoreStateCallCount, 1)
        XCTAssertEqual(client.authenticationStateReads, 1)
    }

    func test_login_updatesAuthenticationStateAndEmail() async {
        let client = AuthenticationClientSpy()
        client.loggedInUserValue = makeUser(email: "user@example.com")
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: client, navigationController: navigationController)

        await sut.loginToQuranCom()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUserEmail, "user@example.com")
        XCTAssertEqual(client.loginCallCount, 1)
        XCTAssertTrue(client.lastLoginViewController === navigationController)
        XCTAssertNil(sut.error)
    }

    func test_login_setsErrorWhenClientIsMissing() async {
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: nil, navigationController: navigationController)

        await sut.loginToQuranCom()

        assertClientIsNotAuthenticated(sut.error)
    }

    func test_logout_clearsAuthenticationStateAndEmail() async {
        let client = AuthenticationClientSpy()
        client.loggedInUserValue = makeUser(email: "user@example.com")
        let sut = makeSUT(authenticationClient: client)
        sut.isAuthenticated = true
        sut.loggedInUser = makeUser(email: "user@example.com")

        await sut.logoutFromQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserEmail)
        XCTAssertEqual(client.logoutCallCount, 1)
        XCTAssertNil(sut.error)
    }

    func test_logout_setsErrorWhenClientIsMissing() async {
        let sut = makeSUT(authenticationClient: nil)

        await sut.logoutFromQuranCom()

        assertClientIsNotAuthenticated(sut.error)
    }

    // MARK: Private

    private func makeSUT(
        authenticationClient: (any AuthenticationClient)?,
        navigationController: UINavigationController = UINavigationController()
    ) -> SettingsRootViewModel {
        let container = AppDependenciesStub(authenticationClient: authenticationClient)
        return SettingsRootViewModel(
            analytics: AnalyticsSpy(),
            reviewService: ReviewService(analytics: AnalyticsSpy()),
            authenticationClient: authenticationClient,
            audioDownloadsBuilder: AudioDownloadsBuilder(container: container),
            translationsListBuilder: TranslationsListBuilder(container: container),
            readingSelectorBuilder: ReadingSelectorBuilder(container: container),
            diagnosticsBuilder: DiagnosticsBuilder(container: container),
            quranProfileURL: container.quranProfileURL,
            navigationController: navigationController
        )
    }

    private func assertClientIsNotAuthenticated(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) {
        guard case .clientIsNotAuthenticated = error as? AuthenticationClientError else {
            return XCTFail("Expected clientIsNotAuthenticated, got \(String(describing: error))", file: file, line: line)
        }
    }
}

private struct AnalyticsSpy: AnalyticsLibrary {
    func logEvent(_: String, value _: String) {}
}

private struct AppDependenciesStub: AppDependencies {
    let authenticationClient: (any AuthenticationClient)?

    var databasesURL: URL { URL(fileURLWithPath: "/tmp") }
    var wordsDatabase: URL { URL(fileURLWithPath: "/tmp/words.db") }
    var appHost: URL { URL(string: "https://quran.com")! }
    var filesAppHost: URL { URL(string: "https://files.quran.com")! }
    var quranProfileURL: URL { URL(string: "https://quran.com/profile")! }
    var logsDirectory: URL { URL(fileURLWithPath: "/tmp/logs") }
    var databasesDirectory: URL { URL(fileURLWithPath: "/tmp") }
    var supportsCloudKit: Bool { false }
    var downloadManager: DownloadManager { fatalError("Unused in tests") }
    var analytics: AnalyticsLibrary { AnalyticsSpy() }
    var readingResources: ReadingResourcesService { fatalError("Unused in tests") }
    var remoteResources: ReadingRemoteResources? { nil }
    var lastPagePersistence: LastPagePersistence { fatalError("Unused in tests") }
    var notePersistence: NotePersistence { fatalError("Unused in tests") }
    var pageBookmarkPersistence: PageBookmarkPersistence { fatalError("Unused in tests") }
}

private func makeUser(email: String?) -> LoggedInUser {
    LoggedInUser(
        id: "1",
        firstName: "Test",
        lastName: "User",
        name: "Test User",
        email: email,
        photoURL: nil
    )
}

private final class AuthenticationClientSpy: AuthenticationClient {
    var restoreStateResult: AuthenticationState = .notAuthenticated
    var restoreStateError: Error?
    var authenticationStateValue: AuthenticationState = .notAuthenticated
    var loggedInUserValue: LoggedInUser?
    var loginError: Error?
    var logoutError: Error?
    var loginCallCount = 0
    var logoutCallCount = 0
    var restoreStateCallCount = 0
    var authenticationStateReads = 0
    weak var lastLoginViewController: UIViewController?

    var authenticationState: AuthenticationState {
        get async {
            authenticationStateReads += 1
            return authenticationStateValue
        }
    }

    var loggedInUser: LoggedInUser? {
        get async { loggedInUserValue }
    }

    func login(on viewController: UIViewController) async throws {
        loginCallCount += 1
        lastLoginViewController = viewController
        if let loginError {
            throw loginError
        }
    }

    func restoreState() async throws -> AuthenticationState {
        restoreStateCallCount += 1
        if let restoreStateError {
            throw restoreStateError
        }
        return restoreStateResult
    }

    func logout() async throws {
        logoutCallCount += 1
        if let logoutError {
            throw logoutError
        }
    }

    func authenticate(request: URLRequest) async throws -> URLRequest {
        request
    }

    func getAuthenticationHeaders() async throws -> [String: String] {
        [:]
    }
}

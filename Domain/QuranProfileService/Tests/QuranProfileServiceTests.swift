import AuthenticationClient
import UIKit
import XCTest
@testable import QuranProfileService

final class QuranProfileServiceTests: XCTestCase {
    func test_refreshAuthenticationState_returnsNotAuthenticated_whenClientIsMissing() async {
        let service = QuranProfileService(authenticationClient: nil)

        let state = await service.refreshAuthenticationState()

        XCTAssertEqual(state, .notAuthenticated)
    }

    func test_refreshAuthenticationState_returnsRestoredState_whenRestoreSucceeds() async {
        let client = AuthenticationClientSpy()
        client.restoreStateResult = .authenticated
        let service = QuranProfileService(authenticationClient: client)

        let state = await service.refreshAuthenticationState()

        XCTAssertEqual(state, .authenticated)
        XCTAssertEqual(client.restoreStateCallCount, 1)
        XCTAssertEqual(client.authenticationStateReads, 0)
    }

    func test_refreshAuthenticationState_fallsBackToCurrentState_whenRestoreFails() async {
        let client = AuthenticationClientSpy()
        client.restoreStateError = NSError(domain: "test", code: 1)
        client.authenticationStateValue = .authenticated
        let service = QuranProfileService(authenticationClient: client)

        let state = await service.refreshAuthenticationState()

        XCTAssertEqual(state, .authenticated)
        XCTAssertEqual(client.restoreStateCallCount, 1)
        XCTAssertEqual(client.authenticationStateReads, 1)
    }

    func test_loginAndLogout_forwardToAuthenticationClient() async throws {
        let client = AuthenticationClientSpy()
        let service = QuranProfileService(authenticationClient: client)
        let viewController = UIViewController()

        try await service.login(on: viewController)
        try await service.logout()

        XCTAssertEqual(client.loginCallCount, 1)
        XCTAssertTrue(client.lastLoginViewController === viewController)
        XCTAssertEqual(client.logoutCallCount, 1)
    }
}

private final class AuthenticationClientSpy: AuthenticationClient {
    var restoreStateResult: AuthenticationState = .notAuthenticated
    var restoreStateError: Error?
    var authenticationStateValue: AuthenticationState = .notAuthenticated
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

    func login(on viewController: UIViewController) async throws {
        loginCallCount += 1
        lastLoginViewController = viewController
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
    }

    func authenticate(request: URLRequest) async throws -> URLRequest {
        request
    }

    func getAuthenticationHeaders() async throws -> [String: String] {
        [:]
    }
}

//
//  AuthenticationClientTests.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 26/12/2024.
//

import AppAuth
import AsyncUtilitiesForTesting
import Combine
import Foundation
import XCTest
@testable import AuthenticationClient

final class AuthenticationClientTests: XCTestCase {
    // MARK: Internal

    let configuration = OAuthAppConfiguration(
        clientID: "client-id",
        redirectURL: URL(string: "callback://")!,
        scopes: [],
        authorizationIssuerURL: URL(string: "https://example.com")!
    )

    override func setUp() {
        caller = OAuthCallerMock()
        persistence = PersistenceMock()
    }

    func testNoConfigurations() async throws {
        XCTAssertEqual(sut.authenticationState, .notAvailable, "Expected to signal a not-configured state")
        await AsyncAssertThrows(
            try await sut.login(on: UIViewController()),
            nil,
            "Expected to throw an error if prompted to login without app configuration being set."
        )
    }

    func testLoginSuccessful() async throws {
        sut.set(appConfiguration: configuration)

        persistence.currentState = AutehenticationDataMock()

        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        caller.loginResult = .success(state)

        try await sut.login(on: UIViewController())

        XCTAssertTrue(persistence.clearCalled, "Expected to clear the persistence first")
        XCTAssertEqual((persistence.currentState as? AutehenticationDataMock), state, "Expected to update the new state")
        XCTAssertEqual(sut.authenticationState, .authenticated, "Expected the auth manager to be in authenticated state")
    }

    func testRestorationSuccessful() async throws {
        sut.set(appConfiguration: configuration)

        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        persistence.currentState = state

        let result = try await sut.restoreState()
        XCTAssert(result, "Expected to be signed in successfully")
        XCTAssertEqual(sut.authenticationState, .authenticated, "Expected the auth manager to be in authenticated state")
    }

    func testRestorationButNotAuthenticated() async throws {
        sut.set(appConfiguration: configuration)

        persistence.currentState = nil

        let result = try await sut.restoreState()
        XCTAssertFalse(result, "Expected to not be signed in")
        XCTAssertEqual(sut.authenticationState, .notAuthenticated)
    }

    func testAuthenticationRequestsWithValidState() async throws {
        sut.set(appConfiguration: configuration)

        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        persistence.currentState = state

        _ = try await sut.restoreState()
        let inputRequest = URLRequest(url: URL(string: "https://example.com")!)

        let result = try await sut.authenticate(request: inputRequest)

        let authHeader = result.allHTTPHeaderFields?.first { $0.key.contains("auth-token") }
        XCTAssertNotNil(authHeader, "Expected to return the access token")
        XCTAssertTrue(authHeader?.value.contains(state.accessToken!) ?? false, "Expeccted to use the access token")

        let clientIDHeader = result.allHTTPHeaderFields?.first { $0.key.contains("client-id") }
        XCTAssertNotNil(clientIDHeader, "Expected to return the client id")
        XCTAssertTrue(clientIDHeader?.value.contains(configuration.clientID) ?? false, "Expeccted to use the client id")
    }

    func testRefreshedTokens() async throws {
        sut.set(appConfiguration: configuration)

        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        persistence.currentState = state

        _ = try await sut.restoreState()

        // Clear the mock persistence for test's sake
        persistence.currentState = nil
        persistence.clearCalled = false

        // Change the state
        state.accessToken = "xyz"

        XCTAssertEqual(
            (persistence.currentState as? AutehenticationDataMock)?.accessToken,
            "xyz",
            "Expected to persist the refreshed state"
        )

        let inputRequest = URLRequest(url: URL(string: "https://example.com")!)
        let resultRequest = try await sut.authenticate(request: inputRequest)
        let authHeader = resultRequest.allHTTPHeaderFields?.first { $0.key.contains("auth-token") }
        XCTAssertEqual(authHeader?.value, "xyz", "Expected to use the refreshed access token for the request")
    }

    // MARK: Private

    private var sut: AuthenticationClientImpl!
    private var caller: OAuthCallerMock!
    private var persistence: PersistenceMock!
}

private final class OAuthCallerMock: OAuthCaller {
    var loginResult: Result<AuthenticationData, Error>?

    func login(
        using configuration: OAuthAppConfiguration,
        on viewController: UIViewController
    ) async throws -> AuthenticationData {
        try loginResult!.get()
    }
}

private final class AutehenticationDataMock: Equatable, AuthenticationData {
    var accessToken: String? {
        didSet {
            guard oldValue != nil else { return }
            subject.send()
        }
    }

    var stateChangedPublisher: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }

    let subject = PassthroughSubject<Void, Never>()

    init() { }

    required init(from decoder: any Decoder) throws {
        fatalError()
    }

    func encode(to encoder: any Encoder) throws {
        fatalError()
    }

    var isAuthorized: Bool {
        accessToken != nil
    }

    func getFreshTokens() async throws -> String {
        guard let token = accessToken else {
            throw AuthenticationStateError.failedToRefreshTokens(nil)
        }
        return token
    }

    static func == (lhs: AutehenticationDataMock, rhs: AutehenticationDataMock) -> Bool {
        lhs.accessToken == rhs.accessToken
    }
}

private final class PersistenceMock: Persistence {
    var clearCalled = false
    var currentState: AuthenticationData?

    func persist(state: AuthenticationData) throws {
        currentState = state
    }

    func retrieve() throws -> AuthenticationData? {
        currentState
    }

    func clear() throws {
        clearCalled = true
        currentState = nil
    }
}

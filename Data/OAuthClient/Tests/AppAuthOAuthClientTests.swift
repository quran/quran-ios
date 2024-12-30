//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 26/12/2024.
//

import Foundation
import AppAuth
import XCTest
import Combine
@testable import OAuthClient

final class AppAuthOAuthClientTests: XCTestCase {

    private var sut: AppAuthOAuthClient!
    private var caller: OAuthCallerMock!
    private var persistance: OAuthClientPersistanceMock!

    let configuration = OAuthAppConfiguration(clientID: "client-id",
                                              redirectURL: URL(string: "callback://")!,
                                              scopes: [],
                                              authorizationIssuerURL: URL(string: "https://example.com")!)

    override func setUp() {
        caller = OAuthCallerMock()
        persistance = OAuthClientPersistanceMock()
        sut = AppAuthOAuthClient(caller: caller, persistance: persistance)
    }

    func testNoConfigurations() async throws {
        XCTAssertEqual(sut.authenticationState, .notAvailable, "Expected to signal a not-configured state")
        do {
            try await sut.login(on: UIViewController())
            XCTFail("Expected to throw an error if prompted to login without app configuration being set.")
        }
        catch {
            // Success
        }
    }

    func testLoginSuccessful() async throws {
        sut.set(appConfiguration: configuration)

        persistance.currentState = AuthenticationData()

        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        caller.loginResult = .success(state)

        do {
            try await sut.login(on: UIViewController())

            XCTAssertTrue(persistance.clearCalled, "Expected to clear the persistance first")
            XCTAssertEqual((persistance.currentState as? AutehenticationDataMock), state, "Expected to update the new state")
            XCTAssertEqual(sut.authenticationState, .authenticated, "Expected the auth manager to be in authenticated state")
        }
        catch {
            XCTFail("Expected to login successfully -- \(error)")
        }
    }

    func testRestorationSuccessful() async throws {
        sut.set(appConfiguration: configuration)

        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        persistance.currentState = state

        do {
            let result = try await sut.restoreState()
            XCTAssert(result, "Expected to be signed in successfully")
            XCTAssertEqual(sut.authenticationState, .authenticated, "Expected the auth manager to be in authenticated state")
        }
        catch {
            XCTFail("Expected to restore the state successfully -- \(error)")
        }
    }

    func testRestorationButNotAuthenticated() async throws {
        sut.set(appConfiguration: configuration)

        persistance.currentState = nil

        do {
            let result = try await sut.restoreState()
            XCTAssertFalse(result, "Expected to not be signed in")
            XCTAssertEqual(sut.authenticationState, .notAuthenticated)
        }
        catch {
            XCTFail("Expected to operation not to fail -- \(error)")
        }
    }

    func testAuthenticationRequestsWithValidState() async throws {
        sut.set(appConfiguration: configuration)

        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        persistance.currentState = state

        do {
            _ = try await sut.restoreState()
            let inputRequest = URLRequest(url: URL(string: "https://example.com")!)

            let result = try await sut.authenticate(request: inputRequest)

            let authHeader = result.allHTTPHeaderFields?.first{ $0.key.contains("auth-token")}
            XCTAssertNotNil(authHeader, "Expected to return the access token")
            XCTAssertTrue(authHeader?.value.contains(state.accessToken!) ?? false, "Expeccted to use the access token")

            let clientIDHeader = result.allHTTPHeaderFields?.first{ $0.key.contains("client-id")}
            XCTAssertNotNil(clientIDHeader, "Expected to return the client id")
            XCTAssertTrue(clientIDHeader?.value.contains(configuration.clientID) ?? false, "Expeccted to use the client id")
        }
        catch {
            XCTFail("Expected to authenticate without an error -- \(error)")
        }
    }

    func testRefreshedTokens() async throws {
        sut.set(appConfiguration: configuration)

        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        persistance.currentState = state

        do {
            _ = try await sut.restoreState()

            // Clear the mock persistance for test's sake
            persistance.currentState = nil
            persistance.clearCalled = false

            // Change the state
            state.accessToken = "xyz"

            XCTAssertEqual((persistance.currentState as? AutehenticationDataMock)?.accessToken, "xyz",
                           "Expected to persist the refreshed state")

            let inputRequest = URLRequest(url: URL(string: "https://example.com")!)
            let resultRequest = try await sut.authenticate(request: inputRequest)
            let authHeader = resultRequest.allHTTPHeaderFields?.first{ $0.key.contains("auth-token")}
            XCTAssertEqual(authHeader?.value, "xyz", "Expected to use the refreshed access token for the request")
        }
        catch {
            XCTFail("Expected not to throw any errors -- \(error)")
        }
    }
}

final private class OAuthCallerMock: OAuthCaller {

    var loginResult: Result<AuthenticationData, Error>?

    func login(using configuration: OAuthClient.OAuthAppConfiguration,
               on viewController: UIViewController) async throws -> AuthenticationData {
        try loginResult!.get()
    }
}

final private class AutehenticationDataMock: AuthenticationData {
    var accessToken: String? {
        didSet {
            guard oldValue != nil else { return }
            subject.send()
        }
    }

    override var stateChangedPublisher: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }

    let subject = PassthroughSubject<Void, Never>()

    override init() {
        super.init()
    }

    required init(from decoder: any Decoder) throws {
        fatalError()
    }

    override var isAuthorized: Bool {
        accessToken != nil
    }

    override func getFreshTokens() async throws -> String {
        guard let token = accessToken else {
            throw AuthenticationStateError.failedToRefreshTokens(nil)
        }
        return token
    }

    static func == (lhs: AutehenticationDataMock, rhs: AutehenticationDataMock) -> Bool {
        lhs.accessToken == rhs.accessToken
    }
}

final private class OAuthClientPersistanceMock: AuthenticationStatePersistance {
    var clearCalled = false
    var currentState: AuthenticationData?

    func persist(state: OAuthClient.AuthenticationData) throws {
        self.currentState = state
    }
    
    func retrieve() throws -> AuthenticationData? {
        currentState
    }
    
    func clear() throws {
        clearCalled = true
        self.currentState = nil
    }
}


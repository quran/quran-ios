//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 26/12/2024.
//

import Foundation
import AppAuth
import XCTest
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

    func testLoginWithoutConfigurations() async throws {
        do {
            try await sut.login(on: UIViewController())
            XCTFail("Expected to throw error")
        }
        catch {
            // TODO
        }
    }

    func testLoginSuccessful() async throws {
        sut.set(appConfiguration: configuration)

        persistance.currentState = AuthenticationState()

        let state = AutehenticationStateMock()
        state.accessToken = "abcd"
        caller.loginResult = .success(state)

        do {
            try await sut.login(on: UIViewController())
        }
        catch {
            XCTFail("Expected to login successfully -- \(error)")
        }
        XCTAssertTrue(persistance.clearCalled, "Expected to clear the persistance first")
        XCTAssertEqual((persistance.currentState as? AutehenticationStateMock), state, "Expected to update the new state")
    }

    func testRestorationSuccessful() async throws {
        sut.set(appConfiguration: configuration)

        let state = AutehenticationStateMock()
        state.accessToken = "abcd"
        persistance.currentState = state

        do {
            let result = try await sut.restoreState()
            XCTAssert(result, "Expected to be signed in successfully")
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
        }
        catch {
            XCTFail("Expected to operation not to fail -- \(error)")
        }
    }

    func testAuthenticationRequestsWithValidState() async throws {
        sut.set(appConfiguration: configuration)

        let state = AutehenticationStateMock()
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
}

final private class OAuthCallerMock: OAuthCaller {

    var loginResult: Result<AuthenticationState, Error>?

    func login(using configuration: OAuthClient.OAuthAppConfiguration,
               on viewController: UIViewController) async throws -> AuthenticationState {
        try loginResult!.get()
    }
}

final private class AutehenticationStateMock: AuthenticationState, Equatable {
    var accessToken: String?

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

    static func == (lhs: AutehenticationStateMock, rhs: AutehenticationStateMock) -> Bool {
        lhs.accessToken == rhs.accessToken
    }
}

final private class OAuthClientPersistanceMock: AuthenticationStatePersistance {
    var clearCalled = false
    var currentState: AuthenticationState?

    func persist(state: OAuthClient.AuthenticationState) throws {
        self.currentState = state
    }
    
    func retrieve() throws -> AuthenticationState? {
        currentState
    }
    
    func clear() throws {
        clearCalled = true
        self.currentState = nil
    }
}


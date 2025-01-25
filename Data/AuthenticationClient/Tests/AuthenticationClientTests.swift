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
import OAuthService
import OAuthServiceFake
import SecurePersistence
import SystemDependencies
import SystemDependenciesFake
import XCTest
@testable import AuthenticationClient

final class AuthenticationClientTests: XCTestCase {
    // MARK: Internal

    let configuration = AuthenticationClientConfiguration(
        clientID: "client-id",
        redirectURL: URL(string: "callback://")!,
        scopes: [],
        authorizationIssuerURL: URL(string: "https://example.com")!
    )

    override func setUp() {
        encoder = OAuthStateEncoderFake()
        oauthService = OAuthServiceFake()
        persistence = KeychainPersistence(keychainAccess: KeychainAccessFake())
        sut = AuthenticationClientImpl(
            configurations: configuration,
            oauthService: oauthService,
            encoder: encoder,
            persistence: persistence
        )
    }

    func testLoginSuccessful() async throws {
        let state = OAuthStateDataFake()
        state.accessToken = "abcd"
        oauthService.loginResult = .success(state)
        oauthService.accessTokenRefreshBehavior = .success("abcd")

        try await sut.login(on: UIViewController())

        await AsyncAssertEqual(
            await sut.authenticationState,
            .authenticated,
            "Expected the auth manager to be in authenticated state"
        )
        XCTAssertEqual(
            try persistence.getData(forKey: AuthenticationClientImpl.persistenceKey)
                .map(encoder.decode(_:)) as? OAuthStateDataFake,
            state,
            "Expected to persist the new state"
        )
    }

    func testLoginFails() async throws {
        oauthService.loginResult = .failure(OAuthServiceError.failedToAuthenticate(nil))

        await AsyncAssertThrows(
            try await sut.login(on: UIViewController()),
            nil,
            "Expected to throw an error"
        )
        await AsyncAssertEqual(await sut.authenticationState, .notAuthenticated, "Expected to not be authenticated")
    }

    func testRestorationSuccessful() async throws {
        let state = OAuthStateDataFake()
        state.accessToken = "abcd"
        try persistence.set(
            data: try encoder.encode(state),
            forKey: AuthenticationClientImpl.persistenceKey
        )
        oauthService.accessTokenRefreshBehavior = .success(state.accessToken!)

        try await AsyncAssertEqual(try await sut.restoreState(), .authenticated, "Expected to be signed in successfully")
        await AsyncAssertEqual(
            await sut.authenticationState,
            .authenticated,
            "Expected the auth manager to be in authenticated state"
        )
    }

    func testRestorationButNotAuthenticated() async throws {
        try await AsyncAssertEqual(try await sut.restoreState(), .notAuthenticated, "Expected to not be signed in")
        await AsyncAssertEqual(await sut.authenticationState, .notAuthenticated, "Should be reflected in state property")
    }

    func testRestorationFailsWithEmptyData() async throws {
        // Persistance starts with empty data.
        try await AsyncAssertEqual(try await sut.restoreState(), .notAuthenticated, "Expected not to be signed in")
    }

    func testRestorationFailsRefreshingSession() async throws {
        let state = OAuthStateDataFake()
        state.accessToken = "abcd"
        try persistence.set(
            data: try encoder.encode(state),
            forKey: AuthenticationClientImpl.persistenceKey
        )
        oauthService.accessTokenRefreshBehavior = .failure(OAuthServiceError.failedToRefreshTokens(nil))

        try await AsyncAssertThrows(await { _ = try await sut.restoreState() }(), nil, "Expected to throw an error")
    }

    func testAuthenticatingRequestsWithValidState() async throws {
        let state = OAuthStateDataFake()
        state.accessToken = "abcd"
        try persistence.set(data: try encoder.encode(state), forKey: AuthenticationClientImpl.persistenceKey)

        oauthService.accessTokenRefreshBehavior = .success("abcd")
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

    func testAuthenticatingRequestFailsGettingToken() async throws {
        let state = OAuthStateDataFake()
        state.accessToken = "abcd"
        try persistence.set(data: try encoder.encode(state), forKey: AuthenticationClientImpl.persistenceKey)

        oauthService.accessTokenRefreshBehavior = .success(state.accessToken!)
        _ = try await sut.restoreState()

        let inputRequest = URLRequest(url: URL(string: "https://example.com")!)

        oauthService.accessTokenRefreshBehavior = .failure(OAuthServiceError.failedToRefreshTokens(nil))

        try await AsyncAssertThrows(
            await { _ = try await sut.authenticate(request: inputRequest) }(),
            nil,
            "Expected to throw an error as well."
        )
        await AsyncAssertEqual(
            await sut.authenticationState,
            .notAuthenticated,
            "Expected to signal not authenticated state"
        )
    }

    func testRefreshedTokens() async throws {
        let state = OAuthStateDataFake()
        state.accessToken = "abcd"
        try persistence.set(
            data: try encoder.encode(state),
            forKey: AuthenticationClientImpl.persistenceKey
        )

        let newState = OAuthStateDataFake()
        newState.accessToken = "xyz"
        oauthService.accessTokenRefreshBehavior = .successWithNewData("xyz", newState)
        _ = try await sut.restoreState()

        let decoded = try persistence.getData(forKey: AuthenticationClientImpl.persistenceKey)
            .map(encoder.decode(_:)) as? OAuthStateDataFake
        XCTAssertEqual(
            decoded?.accessToken,
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
    private var oauthService: OAuthServiceFake!
    private var encoder: OAuthStateDataEncoder!
    private var persistence: SecurePersistence!
}

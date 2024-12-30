//
//  AppAuthOAuthClient.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 23/12/2024.
//

import AppAuth
import Foundation
import UIKit
import VLogging

// TODO: Will need to rename that eventually.
public final class AppAuthOAuthClient: AuthentincationDataManager {
    // MARK: Lifecycle

    private let caller: OAuthCaller
    private let persistance: AuthenticationStatePersistance

    private var state: AuthenticationData?

    init(caller: OAuthCaller, persistance: AuthenticationStatePersistance) {
        self.caller = caller
        self.persistance = persistance
    }

    // MARK: Public

    public var authenticationState: AuthenticationState {
        guard appConfiguration != nil else {
            return .notAvailable
        }
        return state?.isAuthorized == true ? .authenticated : .notAuthenticated
    }

    public func set(appConfiguration: OAuthAppConfiguration) {
        self.appConfiguration = appConfiguration
    }

    public func login(on viewController: UIViewController) async throws {
        // TODO: Probably, we need to catch this and handle it here.
        try persistance.clear()
        logger.info("Cleared previous authentication state")

        guard let configuration = appConfiguration else {
            logger.error("login invoked without OAuth client configurations being set")
            throw OAuthClientError.oauthClientHasNotBeenSet
        }

        let state = try await caller.login(using: configuration, on: viewController)
        self.state = state
        logger.info("login succeeded with state. isAuthorized: \(state.isAuthorized)")
        try persistance.persist(state: state)
    }

    public func restoreState() async throws -> Bool {
        guard appConfiguration != nil else {
            throw OAuthClientError.oauthClientHasNotBeenSet
        }
        guard let state = try persistance.retrieve() else {
            logger.info("No previous authentication state found")
            return false
        }
        // Check authorization state and such.
        // TODO: Called for the side effects!
        _ = try await state.getFreshTokens()
        self.state = state
        return state.isAuthorized
    }

    public func authenticate(request: URLRequest) async throws -> URLRequest {
        guard let configuration = appConfiguration else {
            throw OAuthClientError.oauthClientHasNotBeenSet
        }
        guard let state = self.state else {
            throw OAuthClientError.clientIsNotAuthenticated
        }
        guard state.isAuthorized else {
            throw OAuthClientError.clientIsNotAuthenticated
        }
        let token = try await state.getFreshTokens()
        var request = request
        request.setValue(token, forHTTPHeaderField: "x-auth-token")
        request.setValue(configuration.clientID, forHTTPHeaderField: "x-client-id")
        return request
    }

    // MARK: Private

    private var appConfiguration: OAuthAppConfiguration?
}

extension AppAuthOAuthClient {
    convenience public init() {
        self.init(caller: AppAuthCaller(), persistance: KeychainAuthenticationStatePersistance())
    }
}

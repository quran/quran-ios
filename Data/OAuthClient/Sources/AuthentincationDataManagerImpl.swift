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
import Combine

public final class AuthentincationDataManagerImpl: AuthentincationDataManager {
    // MARK: Lifecycle

    private let caller: OAuthCaller
    private let persistance: AuthenticationStatePersistance

    private var cancellables = Set<AnyCancellable>()

    private var state: AuthenticationData? {
        didSet {
            guard let state = state, oldValue == nil else { return }
            state.stateChangedPublisher.sink { [weak self] _ in
                self?.persist(state: state)
            }.store(in: &cancellables)
        }
    }

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
        guard authenticationState == .authenticated, let state = self.state else {
            throw OAuthClientError.clientIsNotAuthenticated
        }
        let token = try await state.getFreshTokens()
        var request = request
        request.setValue(token, forHTTPHeaderField: "x-auth-token")
        request.setValue(configuration.clientID, forHTTPHeaderField: "x-client-id")
        return request
    }

    private func persist(state: AuthenticationData) {
        do {
            try persistance.persist(state: state)
        } catch {
            logger.error("Failed to persist authentication state: \(error)")
        }
    }

    // MARK: Private

    private var appConfiguration: OAuthAppConfiguration?
}

extension AuthentincationDataManagerImpl {
    convenience public init() {
        self.init(caller: AppAuthCaller(), persistance: KeychainAuthenticationStatePersistance())
    }
}

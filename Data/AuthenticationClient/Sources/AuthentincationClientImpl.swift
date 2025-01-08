//
//  AuthentincationClientImpl.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 23/12/2024.
//

import AppAuth
import Combine
import Foundation
import UIKit
import VLogging

final class AuthenticationClientImpl: AuthenticationClient {
    // MARK: Lifecycle

    init(configurations: OAuthAppConfiguration,
         oauthService: OAuthService,
         encoder: OAuthStateDataEncoder,
         persistence: Persistence) {
        self.oauthService = oauthService
        self.persistence = persistence
        self.encoder = encoder
        self.appConfiguration = configurations
    }

    // MARK: Public

    public var authenticationState: AuthenticationState {
        guard appConfiguration != nil else {
            return .notAvailable
        }
        return stateData?.isAuthorized == true ? .authenticated : .notAuthenticated
    }

    public func login(on viewController: UIViewController) async throws {
        do {
            try persistence.clear()
            logger.info("Cleared previous authentication state before login")
        } catch {
            // If persisting the new state works, this error should be of little concern.
            logger.warning("Failed to clear previous authentication state before login: \(error)")
        }

        guard let _ = appConfiguration else {
            logger.error("login invoked without OAuth client configurations being set")
            throw AuthenticationClientError.oauthClientHasNotBeenSet
        }

        let data = try await oauthService.login(on: viewController)
        self.stateData = data
        logger.info("login succeeded with state. isAuthorized: \(data.isAuthorized)")
        persist(data: data)
    }

    public func restoreState() async throws -> Bool {
        guard appConfiguration != nil else {
            logger.error("restoreState invoked without OAuth client configurations being set")
            throw AuthenticationClientError.oauthClientHasNotBeenSet
        }
        guard let data: Data = try persistence.retrieve() else {
            logger.info("No previous authentication state found")
            return false
        }
        // TODO: Catch and log
        let stateData = try encoder.decode(data)
        let newData = try await oauthService.refreshIfNeeded(data: stateData)
        self.stateData = newData
        self.persist(data: newData)
        return stateData.isAuthorized
    }

    public func authenticate(request: URLRequest) async throws -> URLRequest {
        guard let configuration = appConfiguration else {
            logger.error("authenticate invoked without OAuth client configurations being set")
            throw AuthenticationClientError.oauthClientHasNotBeenSet
        }
        guard authenticationState == .authenticated, let stateData else {
            logger.error("authenticate invoked without client being authenticated")
            throw AuthenticationClientError.clientIsNotAuthenticated
        }
        // TODO: Do we need to catch this?
        let (token, data) = try await oauthService.getAccessToken(using: stateData)
        persist(data: data)
        var request = request
        request.setValue(token, forHTTPHeaderField: "x-auth-token")
        request.setValue(configuration.clientID, forHTTPHeaderField: "x-client-id")
        return request
    }

    // MARK: Private

    private let oauthService: OAuthService
    private let encoder: OAuthStateDataEncoder
    private let persistence: Persistence

    private var stateChangedCancellable: AnyCancellable?

    private var appConfiguration: OAuthAppConfiguration?

    private var stateData: OAuthStateData?

    private func persist(data: OAuthStateData) {
        do {
            let data = try encoder.encode(data)
            try persistence.persist(state: data)
        } catch {
            // If this happens, the state will not nullified so to keep the current session usable
            // for the user. As for now, no workaround is in hand.
            logger.error("Failed to persist authentication state. No workaround in hand.: \(error)")
        }
    }
}

extension AuthenticationClientImpl {
    public convenience init(configurations: OAuthAppConfiguration) {
        let service = AppAuthOAuthService(appConfigurations: configurations)
        let encoder = AppAuthStateEncoder()
        self.init(
            configurations: configurations,
            oauthService: service,
            encoder: encoder,
            persistence: KeychainPersistence()
        )
    }
}

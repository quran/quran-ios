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

final actor AuthenticationClientImpl: AuthenticationClient {
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

    public var authenticationState: AuthenticationState  {
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

        let data = try await oauthService.login(on: viewController)
        self.stateData = data
        logger.info("login succeeded with state. isAuthorized: \(data.isAuthorized)")
        persist(data: data)
    }

    public func restoreState() async throws -> Bool {
        let persistedData: OAuthStateData
        do {
            if let data = try persistence.retrieve() {
                persistedData = try encoder.decode(data)
            } else {
                logger.info("No previous authentication state found")
                return false
            }
        } catch {
            // Aside from requesting the user to share the diagnostic logs, there's no workaround for this.
            logger.error("Failed to refresh the authentication state. Will default to unauthenticated: \(error)")
            return false
        }

        let newData: OAuthStateData
        do {
            newData = try await oauthService.refreshIfNeeded(data: persistedData)
        } catch {
            logger.error("Failed to refresh the authentication state: \(error)")
            throw AuthenticationClientError.clientIsNotAuthenticated(error)
        }
        self.stateData = newData
        self.persist(data: newData)
        return newData.isAuthorized
    }

    public func authenticate(request: URLRequest) async throws -> URLRequest {
        guard authenticationState == .authenticated, let stateData else {
            logger.error("authenticate invoked without client being authenticated")
            throw AuthenticationClientError.clientIsNotAuthenticated(nil)
        }
        // TODO: Do we need to catch this?
        let token: String
        let data: OAuthStateData
        do {
            (token, data) = try await oauthService.getAccessToken(using: stateData)
        } catch {
            logger.error("Failed to get access token. Resetting to non-authenticated state: \(error)")
            self.stateData = nil
            throw AuthenticationClientError.clientIsNotAuthenticated(error)
        }

        persist(data: data)
        var request = request
        request.setValue(token, forHTTPHeaderField: "x-auth-token")
        request.setValue(appConfiguration.clientID, forHTTPHeaderField: "x-client-id")
        return request
    }

    // MARK: Private

    private let oauthService: OAuthService
    private let encoder: OAuthStateDataEncoder
    private let persistence: Persistence

    private var stateChangedCancellable: AnyCancellable?

    private var appConfiguration: OAuthAppConfiguration

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
    public init(configurations: OAuthAppConfiguration) {
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

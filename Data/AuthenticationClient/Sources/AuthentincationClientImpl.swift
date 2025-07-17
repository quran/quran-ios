//
//  AuthentincationClientImpl.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 23/12/2024.
//

import AppAuth
import Combine
import Foundation
import OAuthService
import OAuthServiceAppAuthImpl
import SecurePersistence
import UIKit
import VLogging

public final actor AuthenticationClientImpl: AuthenticationClient {
    // MARK: Lifecycle

    init(
        configurations: AuthenticationClientConfiguration,
        oauthService: OAuthService,
        encoder: OAuthStateDataEncoder,
        persistence: SecurePersistence
    ) {
        self.oauthService = oauthService
        self.persistence = persistence
        self.encoder = encoder
        appConfiguration = configurations
    }

    // MARK: Public

    public var authenticationState: AuthenticationState {
        stateData?.isAuthorized == true ? .authenticated : .notAuthenticated
    }

    public func login(on viewController: UIViewController) async throws {
        do {
            try persistence.clearData(forKey: Self.persistenceKey)
            logger.info("Cleared previous authentication state before login")
        } catch {
            // If persisting the new state works, this error should be of little concern.
            logger.warning("Failed to clear previous authentication state before login: \(error)")
        }

        let data: OAuthStateData
        do {
            data = try await oauthService.login(on: viewController)
            stateData = data
            logger.info("login succeeded with state. isAuthorized: \(data.isAuthorized)")
            persist(data: data)
        } catch {
            logger.error("Failed to login: \(error)")
            throw AuthenticationClientError.errorAuthenticating(error)
        }
    }

    public func restoreState() async throws -> AuthenticationState {
        let persistedData: OAuthStateData
        do {
            if let data = try persistence.getData(forKey: Self.persistenceKey) {
                persistedData = try encoder.decode(data)
            } else {
                logger.info("No previous authentication state found")
                return authenticationState
            }
        } catch {
            // Aside from requesting the user to share the diagnostic logs, there's no workaround for this.
            logger.error("Failed to refresh the authentication state. Will default to unauthenticated: \(error)")
            return authenticationState
        }

        let newData: OAuthStateData
        do {
            newData = try await oauthService.refreshAccessTokenIfNeeded(data: persistedData)
        } catch {
            // We'll need to differentiate between two sets of errors here:
            // - Connectivity and server errors. These should not change the authentication
            //   state. Instead, the clients of `AuthenticationClient` should retry.
            // - Client errors. These should nullify the authentication state.
            //
            // For time sakes, we'll treat all errors as the latter.
            logger.error("Failed to refresh the authentication state: \(error)")
            throw AuthenticationClientError.clientIsNotAuthenticated(error)
        }
        stateData = newData
        persist(data: newData)
        return authenticationState
    }

    public func authenticate(request: URLRequest) async throws -> URLRequest {
        guard authenticationState == .authenticated, let stateData else {
            logger.error("authenticate invoked without client being authenticated")
            throw AuthenticationClientError.clientIsNotAuthenticated(nil)
        }
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

    func getAuthenticationHeaders() async throws -> [String : String] {
        guard authenticationState == .authenticated, let stateData else {
            logger.error("getAuthenticationHeaders called without being authenticated")
            throw AuthenticationClientError.clientIsNotAuthenticated(nil)
        }
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

        return ["x-auth-token": token, "x-client-id": appConfiguration.clientID]
    }

    // MARK: Internal

    static let persistenceKey: String = "com.quran.oauth.state"

    // MARK: Private

    private let oauthService: OAuthService
    private let encoder: OAuthStateDataEncoder
    private let persistence: SecurePersistence

    private var stateChangedCancellable: AnyCancellable?

    private var appConfiguration: AuthenticationClientConfiguration

    private var stateData: OAuthStateData?

    private func persist(data: OAuthStateData) {
        do {
            let data = try encoder.encode(data)
            try persistence.set(data: data, forKey: Self.persistenceKey)
        } catch {
            // If this happens, the state will not nullified so to keep the current session usable
            // for the user. As for now, no workaround is in hand.
            logger.error("Failed to persist authentication state. No workaround in hand.: \(error)")
        }
    }
}

extension AuthenticationClientImpl {
    public init(configurations: AuthenticationClientConfiguration) {
        let service = OAuthServiceAppAuthImpl(configurations: configurations.oAuthServiceConfiguration)
        let encoder = OAuthStateEncoderAppAuthImpl()
        self.init(
            configurations: configurations,
            oauthService: service,
            encoder: encoder,
            persistence: KeychainPersistence()
        )
    }
}

private extension AuthenticationClientConfiguration {
    // The interfaces for the configurations of both modules will change.
    // Noticeably, AuthenticationClient may accept an enum defining the available
    // services. The client may request offline access and profile scopes by default.
    // The OAuth service would still only accept String scopes.
    // On another hand, the issuer host is probably going to be the API host. We
    // may see how the relationship pans out.
    var oAuthServiceConfiguration: AppAuthConfiguration {
        AppAuthConfiguration(
            clientID: clientID,
            redirectURL: redirectURL,
            scopes: scopes,
            authorizationIssuerURL: authorizationIssuerURL
        )
    }
}

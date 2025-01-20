//
//  AppAuthOAuthService.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 08/01/2025.
//

import AppAuth
import Foundation
import OAuthService
import VLogging

struct AppAuthStateData: OAuthStateData {
    let state: OIDAuthState

    var isAuthorized: Bool { state.isAuthorized }
}

struct AppAuthStateEncoder: OAuthStateDataEncoder {
    func encode(_ data: any OAuthStateData) throws -> Data {
        guard let data = data as? AppAuthStateData else {
            fatalError()
        }
        let encoded = try NSKeyedArchiver.archivedData(
            withRootObject: data.state,
            requiringSecureCoding: true
        )
        return encoded
    }

    func decode(_ data: Data) throws -> any OAuthStateData {
        guard let state = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data) else {
            throw OAuthServiceError.stateDataDecodingError(nil)
        }
        return AppAuthStateData(state: state)
    }
}

final class AppAuthOAuthService: OAuthService {
    // MARK: Lifecycle

    init(appConfigurations: AuthenticationClientConfiguration) {
        self.appConfigurations = appConfigurations
    }

    // MARK: Internal

    func login(on viewController: UIViewController) async throws -> any OAuthStateData {
        let serviceConfiguration = try await discoverConfiguration(forIssuer: appConfigurations.authorizationIssuerURL)
        let state = try await login(
            withConfiguration: serviceConfiguration,
            appConfiguration: appConfigurations,
            on: viewController
        )
        return AppAuthStateData(state: state)
    }

    func getAccessToken(using data: any OAuthStateData) async throws -> (String, any OAuthStateData) {
        guard let data = data as? AppAuthStateData else {
            // This should be a fatal error.
            fatalError()
        }
        return try await withCheckedThrowingContinuation { continuation in
            data.state.performAction { accessToken, clientID, error in
                guard error == nil else {
                    logger.error("Failed to refresh tokens: \(error!)")
                    continuation.resume(throwing: OAuthServiceError.failedToRefreshTokens(error))
                    return
                }
                guard let accessToken else {
                    logger.error("Failed to refresh tokens: No access token returned. An unexpected situation.")
                    continuation.resume(throwing: OAuthServiceError.failedToRefreshTokens(nil))
                    return
                }
                let updatedData = AppAuthStateData(state: data.state)
                continuation.resume(returning: (accessToken, updatedData))
            }
        }
    }

    func refreshAccessTokenIfNeeded(data: any OAuthStateData) async throws -> any OAuthStateData {
        try await getAccessToken(using: data).1
    }

    // MARK: Private

    private let appConfigurations: AuthenticationClientConfiguration

    // Needed mainly for retention.
    private var authFlow: (any OIDExternalUserAgentSession)?

    // MARK: - Authenication Flow

    private func discoverConfiguration(forIssuer issuer: URL) async throws -> OIDServiceConfiguration {
        logger.info("Discovering configuration for OAuth")
        return try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService
                .discoverConfiguration(forIssuer: issuer) { configuration, error in
                    guard error == nil else {
                        logger.error("Error fetching OAuth configuration: \(error!)")
                        continuation.resume(throwing: OAuthServiceError.failedToDiscoverService(error))
                        return
                    }
                    guard let configuration else {
                        // This should not happen
                        logger.error("Error fetching OAuth configuration: no configuration was loaded. An unexpected situtation.")
                        continuation.resume(throwing: OAuthServiceError.failedToDiscoverService(nil))
                        return
                    }
                    logger.info("OAuth configuration fetched successfully")
                    continuation.resume(returning: configuration)
                }
        }
    }

    private func login(
        withConfiguration configuration: OIDServiceConfiguration,
        appConfiguration: AuthenticationClientConfiguration,
        on viewController: UIViewController
    ) async throws -> OIDAuthState {
        let scopes = [OIDScopeOpenID, OIDScopeProfile] + appConfiguration.scopes
        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: appConfiguration.clientID,
            clientSecret: nil,
            scopes: scopes,
            redirectURL: appConfiguration.redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: [:]
        )

        logger.info("Starting OAuth flow")
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.authFlow = OIDAuthState.authState(
                    byPresenting: request,
                    presenting: viewController
                ) { [weak self] state, error in
                    self?.authFlow = nil
                    guard error == nil else {
                        logger.error("Error authenticating: \(error!)")
                        continuation.resume(throwing: OAuthServiceError.failedToAuthenticate(error))
                        return
                    }
                    guard let state else {
                        logger.error("Error authenticating: no state returned. An unexpected situtation.")
                        continuation.resume(throwing: OAuthServiceError.failedToAuthenticate(nil))
                        return
                    }
                    logger.info("OAuth flow completed successfully")
                    continuation.resume(returning: state)
                }
            }
        }
    }
}

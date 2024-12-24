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

public final class AppAuthOAuthClient: OAuthClient {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func set(appConfiguration: OAuthAppConfiguration) {
        self.appConfiguration = appConfiguration
    }

    public func login(on viewController: UIViewController) async throws {
        guard let configuration = appConfiguration else {
            logger.error("login invoked without OAuth client configurations being set")
            throw OAuthClientError.oauthClientHasNotBeenSet
        }

        // Quran.com relies on dicovering the service configuration from the issuer,
        // and not using a static configuration.
        let serviceConfiguration = try await discoverConfiguration(forIssuer: configuration.authorizationIssuerURL)
        try await login(
            withConfiguration: serviceConfiguration,
            appConfiguration: configuration,
            on: viewController
        )
    }

    // MARK: Private

    // Needed mainly for retention.
    private var authFlow: (any OIDExternalUserAgentSession)?
    private var appConfiguration: OAuthAppConfiguration?

    // MARK: - Authenication Flow

    private func discoverConfiguration(forIssuer issuer: URL) async throws -> OIDServiceConfiguration {
        logger.info("Discovering configuration for OAuth")
        return try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService
                .discoverConfiguration(forIssuer: issuer) { configuration, error in
                    guard error == nil else {
                        logger.error("Error fetching OAuth configuration: \(error!)")
                        continuation.resume(throwing: OAuthClientError.errorFetchingConfiguration(error))
                        return
                    }
                    guard let configuration else {
                        // This should not happen
                        logger.error("Error fetching OAuth configuration: no cofniguration was loaded. An unexpected situtation.")
                        continuation.resume(throwing: OAuthClientError.errorFetchingConfiguration(nil))
                        return
                    }
                    logger.info("OAuth configuration fetched successfully")
                    continuation.resume(returning: configuration)
                }
        }
    }

    private func login(
        withConfiguration configuration: OIDServiceConfiguration,
        appConfiguration: OAuthAppConfiguration,
        on viewController: UIViewController
    ) async throws {
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
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            fire(loginRequest: request, on: viewController) { state, error in
                guard error == nil else {
                    logger.error("Error authenticating: \(error!)")
                    continuation.resume(throwing: OAuthClientError.errorAuthenticating(error))
                    return
                }
                guard let _ = state else {
                    logger.error("Error authenticating: no state returned. An unexpected situtation.")
                    continuation.resume(throwing: OAuthClientError.errorAuthenticating(nil))
                    return
                }
                logger.info("OAuth flow completed successfully")
                continuation.resume()
            }
        }
    }

    /// Executes the request on the main actor.
    private func fire(
        loginRequest: OIDAuthorizationRequest,
        on viewController: UIViewController,
        callback: @escaping OIDAuthStateAuthorizationCallback
    ) {
        Task {
            await MainActor.run {
                authFlow = OIDAuthState.authState(
                    byPresenting: loginRequest,
                    presenting: viewController
                ) { [weak self] state, error in
                    self?.authFlow = nil
                    callback(state, error)
                }
            }
        }
    }
}

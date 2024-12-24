//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 23/12/2024.
//

import Foundation
import UIKit
import AppAuth

public final class AppAuthOAuthClient: OAuthClient {

    // Needed mainly for retention.
    private var authFlow: (any OIDExternalUserAgentSession)?
    private var appConfiguration: OAuthAppConfiguration?

    public init() {}

    public func set(appConfiguration: OAuthAppConfiguration) {
        self.appConfiguration = appConfiguration
    }

    public func login(on viewController: UIViewController) async throws {
        guard let configuration = self.appConfiguration else {
            throw OAuthClientError.oauthClientHasNotBeenSet
        }

        // Quran.com relies on dicovering the configuration from the issuer, and not using a static configuration.
        let serviceConfiguration = try await discoverConfiguration(forIssuer: configuration.authorizationIssuerURL)
        try await login(withConfiguration: serviceConfiguration,
                        appConfiguration: configuration,
                        on: viewController)
    }

    private func discoverConfiguration(forIssuer issuer: URL) async throws -> OIDServiceConfiguration {
        try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService
                .discoverConfiguration(forIssuer: issuer) { configuration, error in
                    guard error == nil else {
                        continuation.resume(throwing: OAuthClientError.errorFetchingConfiguration(error))
                        return
                    }
                    guard let configuration = configuration else {
                        // This should not happen
                        continuation.resume(throwing: OAuthClientError.errorFetchingConfiguration(nil))
                        return
                    }
                    continuation.resume(returning: configuration)
                }
        }
    }

    private func login(withConfiguration configuration: OIDServiceConfiguration,
                       appConfiguration: OAuthAppConfiguration,
                       on viewController: UIViewController) async throws {
        let scopes = [OIDScopeOpenID, OIDScopeProfile] + appConfiguration.scopes
        let request = OIDAuthorizationRequest(configuration: configuration,
                                              clientId: appConfiguration.clientID,
                                              clientSecret: nil,
                                              scopes: scopes,
                                              redirectURL: appConfiguration.redirectURL,
                                              responseType: OIDResponseTypeCode,
                                              additionalParameters: [:])

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            fire(loginRequest: request, on: viewController) { state, error in
                guard error == nil else {
                    continuation.resume(throwing: OAuthClientError.errorAuthenticating(error))
                    return
                }
                guard let state = state else {
                    continuation.resume(throwing: OAuthClientError.errorAuthenticating(nil))
                    return
                }
                print(state)
                continuation.resume()
            }
        }
    }

    /// Executes the request on the main actor.
    private func fire(loginRequest: OIDAuthorizationRequest,
                      on viewController: UIViewController,
                      callback: @escaping OIDAuthStateAuthorizationCallback) {
        Task {
            await MainActor.run {
                self.authFlow = OIDAuthState.authState(byPresenting: loginRequest,
                                                       presenting: viewController) { state, error in
                    self.authFlow = nil
                    callback(state, error)
                }
            }
        }
    }
}

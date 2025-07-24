//
//  AuthenticationClient.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 19/12/2024.
//

import Foundation
import UIKit

public enum AuthenticationClientError: Error {
    case errorAuthenticating(Error?)

    /// Thrown when an operation, that needs authentication, is attempted while the client
    /// hasn't been authenticated or if the client's access has been revoked.
    case clientIsNotAuthenticated(Error?)
}

public enum AuthenticationState: Equatable {
    /// No user is currently authenticated, or access has been revoked or is expired.
    /// Logging in is availble and is required for further APIs.
    case notAuthenticated

    case authenticated
}

public struct AuthenticationClientConfiguration {
    public let clientID: String
    public let clientSecret: String
    public let redirectURL: URL
    /// Indicates the Quran.com specific scopes to be requested by the app.
    /// The client requests the `offline` and `openid` scopes by default.
    public let scopes: [String]
    /// Quran.com relies on dicovering the service configuration from the issuer,
    /// and not using a static configuration.
    public let authorizationIssuerURL: URL

    public init(clientID: String, clientSecret: String, redirectURL: URL, scopes: [String], authorizationIssuerURL: URL) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURL = redirectURL
        self.scopes = scopes
        self.authorizationIssuerURL = authorizationIssuerURL
    }
}

/// Handles the OAuth flow to Quran.com
///
/// Expected to be configuered with the host app's OAuth configuration before further operations are attempted.
public protocol AuthenticationClient {
    /// Performs the login flow to Quran.com
    ///
    /// - Parameter viewController: The view controller to be used as base for presenting the login flow.
    /// - Returns: Nothing is returned for now. The client may return the profile infromation in the future.
    func login(on viewController: UIViewController) async throws

    func restoreState() async throws -> AuthenticationState

    func authenticate(request: URLRequest) async throws -> URLRequest

    func getAuthenticationHeaders() async throws -> [String: String]

    var authenticationState: AuthenticationState { get async }
}

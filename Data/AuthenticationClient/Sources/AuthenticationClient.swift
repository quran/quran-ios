//
//  AuthenticationClient.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 19/12/2024.
//

import Foundation
import UIKit

public enum AuthenticationClientError: Error {
    case oauthClientHasNotBeenSet
    case errorAuthenticating(Error?)

    /// Thrown when an operation, that needs authentication, is attempted while the client
    /// hasn't been authenticated or if the client's access has been revoked.
    case clientIsNotAuthenticated
}

public enum AuthenticationState: Equatable {
    /// Authentication is not available. Any action dependent on authentication
    /// (such as logging in or invoking user APIs) should not be attempted..
    case notAvailable

    /// No user is currently authenticated, or access has been revoked or is expired.
    /// Logging in is availble and is required for further APIs.
    case notAuthenticated

    case authenticated
}

public struct OAuthAppConfiguration {
    public let clientID: String
    public let redirectURL: URL
    /// Indicates the Quran.com specific scopes to be requested by the app.
    /// The client requests the `offline` and `openid` scopes by default.
    public let scopes: [String]
    public let authorizationIssuerURL: URL

    public init(clientID: String, redirectURL: URL, scopes: [String], authorizationIssuerURL: URL) {
        self.clientID = clientID
        self.redirectURL = redirectURL
        self.scopes = scopes
        self.authorizationIssuerURL = authorizationIssuerURL
    }
}

/// Handles the OAuth flow to Quran.com
///
/// Expected to be configuered with the host app's OAuth configuration before further operations are attempted.
public protocol AuthenticationClient {
    /// Sets the app configuration to be used for authentication.
    func set(appConfiguration: OAuthAppConfiguration)

    /// Performs the login flow to Quran.com
    ///
    /// - Parameter viewController: The view controller to be used as base for presenting the login flow.
    /// - Returns: Nothing is returned for now. The client may return the profile infromation in the future.
    func login(on viewController: UIViewController) async throws

    /// Returns `true` if the client is authenticated.
    func restoreState() async throws -> Bool

    func authenticate(request: URLRequest) async throws -> URLRequest

    var authenticationState: AuthenticationState { get }
}

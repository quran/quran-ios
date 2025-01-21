//
//  OAuthService.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 08/01/2025.
//

import Foundation
import UIKit

public struct OAuthServiceConfiguration {
    public let clientID: String
    public let redirectURL: URL
    /// Indicates the Quran.com specific scopes to be requested by the app.
    /// The client requests the `offline` and `openid` scopes by default.
    public let scopes: [String]
    /// Quran.com relies on dicovering the service configuration from the issuer,
    /// and not using a static configuration.
    public let authorizationIssuerURL: URL

    public init(clientID: String, redirectURL: URL, scopes: [String], authorizationIssuerURL: URL) {
        self.clientID = clientID
        self.redirectURL = redirectURL
        self.scopes = scopes
        self.authorizationIssuerURL = authorizationIssuerURL
    }
}

public enum OAuthServiceError: Error {
    case failedToRefreshTokens(Error?)

    case stateDataDecodingError(Error?)

    case failedToDiscoverService(Error?)

    case failedToAuthenticate(Error?)
}

/// Encapsulates the OAuth state data. Should only be managed and mutated by `OAuthService.`
public protocol OAuthStateData {
    var isAuthorized: Bool { get }
}

/// An abstraction for handling the OAuth flow steps.
///
/// The service is assumed not to have any internal state. It's the responsibility of the client of this service
/// to hold and persist the state data. Each call to the service returns an updated `OAuthStateData`
/// that reflects the latest state.
public protocol OAuthService {
    /// Attempts to discover the authentication services and redirects the user to the authentication service.
    func login(on viewController: UIViewController) async throws -> OAuthStateData

    func getAccessToken(using data: OAuthStateData) async throws -> (String, OAuthStateData)

    func refreshAccessTokenIfNeeded(data: OAuthStateData) async throws -> OAuthStateData
}

/// Encodes and decodes the `OAuthStateData`. A convneience to hide the conforming `OAuthStateData` type
/// while preparing the state for persistence.
public protocol OAuthStateDataEncoder {
    func encode(_ data: OAuthStateData) throws -> Data

    func decode(_ data: Data) throws -> OAuthStateData
}

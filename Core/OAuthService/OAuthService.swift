//
//  OAuthService.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 08/01/2025.
//

import Foundation
import UIKit

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
    func login(on viewController: UIViewController) async throws -> OAuthStateData

    func getAccessToken(using data: OAuthStateData) async throws -> (String, OAuthStateData)

    func refreshIfNeeded(data: OAuthStateData) async throws -> OAuthStateData
}

/// Encodes and decodes the `OAuthStateData`. A convneience to hide the conforming `OAuthStateData` type
/// while preparing the state for persistence.
public protocol OAuthStateDataEncoder {
    func encode(_ data: OAuthStateData) throws -> Data

    func decode(_ data: Data) throws -> OAuthStateData
}

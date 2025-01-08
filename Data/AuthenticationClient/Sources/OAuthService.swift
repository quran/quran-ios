//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 08/01/2025.
//

import Foundation
import UIKit

enum OAuthServiceError: Error {
    /// Throws when the refresh token operation fails. Assume that the user is not authenticated anymore.
    case failedToRefreshTokens(Error?)

    /// Failed to decode the persisted state back.
    case decodingError(Error?)

    case failedToDiscoverService(Error?)

    case failedToAuthenticate(Error?)
}

protocol OAuthStateData {

    var isAuthorized: Bool { get }
}

protocol OAuthService {

    func login(on viewController: UIViewController) async throws -> OAuthStateData

    func getAccessToken(using data: OAuthStateData) async throws -> (String, OAuthStateData)

    func refreshIfNeeded(data: OAuthStateData) async throws -> OAuthStateData
}

protocol OAuthStateDataEncoder {

    func encode(_ data: OAuthStateData) throws -> Data

    func decode(_ data: Data) throws -> OAuthStateData
}

protocol OAuthServiceBuilder {

    func buildService(appConfigurations: OAuthAppConfiguration) -> OAuthService
    func buildEncoder() -> OAuthStateDataEncoder
}

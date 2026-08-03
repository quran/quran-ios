//
//  AuthenticationClient.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 19/12/2024.
//

#if QURAN_SYNC

import Foundation
import MobileSync
import UIKit

public enum AuthenticationClientError: Error {
    /// The user dismissed the interactive authentication flow.
    case cancelled

    /// An authenticated operation was attempted without a usable session.
    case notAuthenticated(underlying: Error?)

    /// Authentication could not reach the remote service.
    case networkFailure(underlying: Error)

    /// Authentication failed for a non-network reason.
    case authenticationFailed(underlying: Error)

    public var underlyingError: Error? {
        switch self {
        case .cancelled:
            nil
        case let .notAuthenticated(underlyingError):
            underlyingError
        case let .networkFailure(underlyingError),
             let .authenticationFailed(underlyingError):
            Optional(underlyingError)
        }
    }
}

public enum AuthenticationState: Equatable {
    /// No user is currently authenticated, or access has been revoked or is expired.
    /// Logging in is availble and is required for further APIs.
    case notAuthenticated

    case authenticated
}

/// Handles the OAuth flow to Quran.com
///
/// Expected to be configuered with the host app's OAuth configuration before further operations are attempted.
public protocol AuthenticationClient {
    /// Performs the login flow to Quran.com
    ///
    /// - Parameter viewController: The view controller to be used as base for presenting the login flow.
    /// - Returns: Nothing is returned for now. The client may return the profile infromation in the future.
    func login(on viewController: UIViewController) async throws(AuthenticationClientError)

    func restoreState() async throws(AuthenticationClientError) -> AuthenticationState

    func logout() async throws(AuthenticationClientError)

    func authenticate(request: URLRequest) async throws(AuthenticationClientError) -> URLRequest

    func getAuthenticationHeaders() async throws(AuthenticationClientError) -> [String: String]

    var authenticationState: AuthenticationState { get async }
    var loggedInUser: UserInfo? { get async }
}

public extension AuthenticationClient {
    func safelyRestoreState() async -> AuthenticationState {
        do {
            return try await restoreState()
        } catch {
            return await authenticationState
        }
    }
}

#endif

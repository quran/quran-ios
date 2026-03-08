//
//  QuranProfileService.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 23/12/2024.
//

import AuthenticationClient
import UIKit

public class QuranProfileService {
    private let authenticationClient: AuthenticationClient?

    public init(authenticationClient: AuthenticationClient?) {
        self.authenticationClient = authenticationClient
    }

    public var isAuthenticationAvailable: Bool {
        authenticationClient != nil
    }

    public func authenticationState() async -> AuthenticationState {
        guard let authenticationClient else {
            return .notAuthenticated
        }
        return await authenticationClient.authenticationState
    }

    public func restoreState() async throws -> AuthenticationState {
        guard let authenticationClient else {
            return .notAuthenticated
        }
        return try await authenticationClient.restoreState()
    }

    /// Performs the login flow to Quran.com
    ///
    /// - Parameter viewController: The view controller to be used as base for presenting the login flow.
    /// - Returns: Nothing is returned for now. The client may return the profile infromation in the future.
    public func login(on viewController: UIViewController) async throws {
        try await authenticationClient?.login(on: viewController)
    }

    public func logout() async throws {
        try await authenticationClient?.logout()
    }
}

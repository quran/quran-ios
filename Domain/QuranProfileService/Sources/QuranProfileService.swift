//
//  QuranProfileService.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 23/12/2024.
//

import AuthenticationClient
import UIKit

public final class QuranProfileService {
    // MARK: Lifecycle

    public init(authenticationClient: AuthenticationClient?) {
        self.authenticationClient = authenticationClient
    }

    // MARK: Public

    public func refreshAuthenticationState() async -> AuthenticationState {
        guard let authenticationClient else {
            return .notAuthenticated
        }

        do {
            return try await authenticationClient.restoreState()
        } catch {
            return await authenticationClient.authenticationState
        }
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

    // MARK: Private

    private let authenticationClient: AuthenticationClient?
}

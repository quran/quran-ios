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

    /// Performs the login flow to Quran.com
    ///
    /// - Parameter viewController: The view controller to be used as base for presenting the login flow.
    /// - Returns: Nothing is returned for now. The client may return the profile infromation in the future.
    public func login(on viewController: UIViewController) async throws {
        try await authenticationClient?.login(on: viewController)
    }
}

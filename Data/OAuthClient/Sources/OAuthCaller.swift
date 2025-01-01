//
//  OAuthCaller.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 26/12/2024.
//

import AppAuth
import UIKit

/// Encapsulates the logic to perform OAuth login.
///
/// The abstraction is added for testing purposes.
protocol OAuthCaller {
    func login(
        using configuration: OAuthAppConfiguration,
        on viewController: UIViewController
    ) async throws -> AuthenticationData
}

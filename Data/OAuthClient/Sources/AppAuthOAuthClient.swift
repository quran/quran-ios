//
//  AppAuthOAuthClient.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 23/12/2024.
//

import AppAuth
import Foundation
import UIKit
import VLogging

// TODO: Will need to rename that eventually.
public final class AppAuthOAuthClient: AuthentincationDataManager {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func set(appConfiguration: OAuthAppConfiguration) {
        self.appConfiguration = appConfiguration
    }

    public func login(on viewController: UIViewController) async throws {
        guard let configuration = appConfiguration else {
            logger.error("login invoked without OAuth client configurations being set")
            throw OAuthClientError.oauthClientHasNotBeenSet
        }

        let caller = AppAuthCaller()
        let state = try await caller.login(using: configuration, on: viewController)
        logger.info("login succeeded with state. isAuthorized: \(state.isAuthorized)")
        let persistance = KeychainAuthenticationStatePersistance()
        try persistance.persist(state: state)
    }

    // MARK: Private

    private var appConfiguration: OAuthAppConfiguration?
}

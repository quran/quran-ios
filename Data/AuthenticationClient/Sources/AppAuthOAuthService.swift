//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 08/01/2025.
//

import Foundation
import AppAuth

final class AppAuthOAuthService: OAuthService {

    private let appConfigurations: OAuthAppConfiguration

    init(appConfigurations: OAuthAppConfiguration) {
        self.appConfigurations = appConfigurations
    }

    func login(on viewController: UIViewController) async throws -> any OAuthStateData {

    }

    func getAccessToken(using data: any OAuthStateData) async throws -> String {
        fatalError()
    }
}

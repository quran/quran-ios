//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 23/12/2024.
//

import UIKit
import OAuthClient

public class QuranProfileService {

    private let oauthClient: OAuthClient

    public init(oauthClient: OAuthClient) {
        self.oauthClient = oauthClient
    }

    public func login(on viewController: UIViewController) async throws {
        try await oauthClient.login(on: viewController)
    }
}


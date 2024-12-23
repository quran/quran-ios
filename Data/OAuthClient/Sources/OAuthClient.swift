//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 19/12/2024.
//

import Foundation
import UIKit

public enum OAuthClientError: Error {
    case oauthClientHasNotBeenSet
    case errorFetchingConfiguration(Error?)
    case errorAuthenticating(Error?)
}

public struct OAuthAppConfiguration {
    public let clientID: String
    public let redirectURL: URL
    public let scopes: [String]
    public let authorizationHost: URL
}

public protocol OAuthClient {
    
    func set(appConfiguration: OAuthAppConfiguration)

    // TODO: May return the profile information
    func login(on viewController: UIViewController) async throws
}

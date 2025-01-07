//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 08/01/2025.
//

import Foundation
import UIKit

protocol OAuthStateData {

}

protocol OAuthService {

    func login(on viewController: UIViewController) async throws -> OAuthStateData

    func getAccessToken(using data: OAuthStateData) async throws -> String
}

protocol OAuthStateDataEncoder {

    func encode(_ data: OAuthStateData) throws -> Data

    func decode(_ data: Data) throws -> OAuthStateData
}

protocol OAuthServiceBuilder {

    func buildService(appConfigurations: OAuthAppConfiguration) -> OAuthService
    func buildEncoder() -> OAuthStateDataEncoder
}

//
//  OAuthCaller.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 26/12/2024.
//

import AppAuth
import UIKit

protocol OAuthCaller {

    func login(using configuration: OAuthAppConfiguration,
               on viewController: UIViewController) async throws -> AuthenticationState
}

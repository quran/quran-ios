//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 19/12/2024.
//

import Foundation


// TODO: Need to add functions for authenticating the requests and getting the profile information.
public final protocol OAuthClient {
    
    public func set(clientID: String)
    
    // TODO: May return the profile information
    public func login(on viewController: UIViewController) async throws
}

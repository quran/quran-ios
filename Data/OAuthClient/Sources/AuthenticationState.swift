//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 27/12/2024.
//

import Foundation
import AppAuth
import VLogging

enum AuthenticationStateError: Error {
    case failedToRefreshTokens(Error?)
}

class AuthenticationState: Codable {

    var isAuthorized: Bool {
        fatalError()
    }

    func getFreshTokens() async throws -> String {
        fatalError()
    }

    init() { }
    required init(from decoder: any Decoder) throws {
        fatalError()
    }
}

class AppAuthAuthenticationState: AuthenticationState {
    private enum CodingKeys: String, CodingKey {
        case state
    }

    private var state: OIDAuthState?

    override var isAuthorized: Bool {
        state?.isAuthorized ?? false
    }

    init(state: OIDAuthState? = nil) {
        self.state = state
        super.init()
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let data = try container.decodeIfPresent(Data.self, forKey: .state) {
            self.state = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data)
        }
        super.init()
    }

    override func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        if let state {
            let data = try NSKeyedArchiver.archivedData(withRootObject: state, requiringSecureCoding: true)
            try container.encode(data, forKey: .state)
        }
        else {
            try container.encodeNil(forKey: .state)
        }
    }

    override func getFreshTokens() async throws -> String {
        guard let state = state else {
            // TODO: We need to define proper errors here.
            throw NSError()
        }
        return try await withCheckedThrowingContinuation { continuation in
            state.performAction { accessToken, clientID, error in
                guard error == nil else {
                    logger.error("Failed to refresh tokens: \(error!)")
                    continuation.resume(throwing: AuthenticationStateError.failedToRefreshTokens(error))
                    return
                }
                guard let accessToken = accessToken else {
                    logger.error("Failed to refresh tokens: No access token returned. An unexpected situation.")
                    continuation.resume(throwing: AuthenticationStateError.failedToRefreshTokens(nil))
                    return
                }
                continuation.resume(returning: accessToken)
            }
        }
    }
}

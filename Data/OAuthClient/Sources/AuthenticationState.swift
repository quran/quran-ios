//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 27/12/2024.
//

import Foundation
import AppAuth

class AuthenticationState: Codable {

    var isAuthorized: Bool {
        fatalError()
    }

    func getFreshTokens() async throws -> OIDTokenResponse {
        fatalError()
    }

    fileprivate init() { }
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
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        if let state {
            let data = try NSKeyedArchiver.archivedData(withRootObject: state, requiringSecureCoding: true)
            try container.encode(data, forKey: .state)
        }
        else {
            try container.encodeNil(forKey: .state)
        }
    }
}

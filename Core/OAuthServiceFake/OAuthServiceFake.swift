//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 22/01/2025.
//

import UIKit
import OAuthService

public struct OAuthStateEncoderFake: OAuthStateDataEncoder {
    public init() {}

    public func encode(_ data: any OAuthStateData) throws -> Data {
        guard let data = data as? OAuthStateDataFake else {
            fatalError()
        }
        return try JSONEncoder().encode(data)
    }

    public func decode(_ data: Data) throws -> any OAuthStateData {
        try JSONDecoder().decode(OAuthStateDataFake.self, from: data)
    }
}

public final class OAuthServiceFake: OAuthService {
    public enum AccessTokenBehavior {
        case success(String)
        case successWithNewData(String, any OAuthStateData)
        case failure(Error)

        func getToken() throws -> String {
            switch self {
            case .success(let token), .successWithNewData(let token, _):
                return token
            case .failure(let error):
                throw error
            }
        }

        func getStateData() throws -> (any OAuthStateData)? {
            switch self {
            case .success:
                return nil
            case .successWithNewData(_, let data):
                return data
            case .failure(let error):
                throw error
            }
        }
    }

    public init() {}

    public var loginResult: Result<OAuthStateData, Error>?

    public func login(on viewController: UIViewController) async throws -> any OAuthStateData {
        try loginResult!.get()
    }

    public var accessTokenRefreshBehavior: AccessTokenBehavior?

    public func getAccessToken(using data: any OAuthStateData) async throws -> (String, any OAuthStateData) {
        guard let behavior = accessTokenRefreshBehavior else {
            fatalError()
        }
        return (try behavior.getToken(), try behavior.getStateData() ?? data)
    }

    public func refreshAccessTokenIfNeeded(data: any OAuthStateData) async throws -> any OAuthStateData {
        try await getAccessToken(using: data).1
    }
}

public final class OAuthStateDataFake: Equatable, Codable, OAuthStateData {
    enum Codingkey: String, CodingKey {
        case accessToken
    }

    public var accessToken: String? {
        didSet {
            guard oldValue != nil else { return }
        }
    }

    public init() { }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Codingkey.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Codingkey.self)
        try container.encode(accessToken, forKey: .accessToken)
    }

    public var isAuthorized: Bool {
        accessToken != nil
    }

    public static func == (lhs: OAuthStateDataFake, rhs: OAuthStateDataFake) -> Bool {
        lhs.accessToken == rhs.accessToken
    }
}

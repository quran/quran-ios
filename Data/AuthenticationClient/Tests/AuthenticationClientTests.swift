//
//  AuthenticationClientTests.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 26/12/2024.
//

import AppAuth
import AsyncUtilitiesForTesting
import Combine
import Foundation
import XCTest
@testable import AuthenticationClient

final class AuthenticationClientTests: XCTestCase {
    // MARK: Internal

    let configuration = OAuthAppConfiguration(
        clientID: "client-id",
        redirectURL: URL(string: "callback://")!,
        scopes: [],
        authorizationIssuerURL: URL(string: "https://example.com")!
    )

    override func setUp() {
        encoder = OauthStateEncoderMock()
        oauthService = OAuthServiceMock()
        persistence = PersistenceMock()
        sut = AuthenticationClientImpl(configurations: configuration,
                                       oauthService: oauthService,
                                       encoder: encoder,
                                       persistence: persistence)
    }

//    func testNoConfigurations() async throws {
//        sut = AuthenticationClientImpl(configurations: nil, caller: caller, persistence: persistence)
//        XCTAssertEqual(sut.authenticationState, .notAvailable, "Expected to signal a not-configured state")
//        await AsyncAssertThrows(
//            try await sut.login(on: UIViewController()),
//            nil,
//            "Expected to throw an error if prompted to login without app configuration being set."
//        )
//    }

    func testLoginSuccessful() async throws {
        persistence.data = Data()

        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        oauthService.loginResult = .success(state)
        oauthService.accessTokenBehavior = .success("abcd")

        try await sut.login(on: UIViewController())

        XCTAssertTrue(persistence.clearCalled, "Expected to clear the persistence first")
        XCTAssertEqual(sut.authenticationState, .authenticated, "Expected the auth manager to be in authenticated state")

        XCTAssertEqual(try persistence.data.map(encoder.decode(_:)) as? AutehenticationDataMock,
                       state,
                       "Expected to persist the new state")
    }

    func testRestorationSuccessful() async throws {
        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        persistence.data = try encoder.encode(state)
        oauthService.refreshResult = .success(nil)

        let result = try await sut.restoreState()
        XCTAssert(result, "Expected to be signed in successfully")
        XCTAssertEqual(sut.authenticationState, .authenticated, "Expected the auth manager to be in authenticated state")
    }

    func testRestorationButNotAuthenticated() async throws {
        persistence.data = nil

        let result = try await sut.restoreState()
        XCTAssertFalse(result, "Expected to not be signed in")
        XCTAssertEqual(sut.authenticationState, .notAuthenticated)
    }

    func testAuthenticationRequestsWithValidState() async throws {
        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        persistence.data = try encoder.encode(state)

        oauthService.accessTokenBehavior = .success("abcd")
        oauthService.refreshResult = .success(nil)
        _ = try await sut.restoreState()
        let inputRequest = URLRequest(url: URL(string: "https://example.com")!)

        let result = try await sut.authenticate(request: inputRequest)

        let authHeader = result.allHTTPHeaderFields?.first { $0.key.contains("auth-token") }
        XCTAssertNotNil(authHeader, "Expected to return the access token")
        XCTAssertTrue(authHeader?.value.contains(state.accessToken!) ?? false, "Expeccted to use the access token")

        let clientIDHeader = result.allHTTPHeaderFields?.first { $0.key.contains("client-id") }
        XCTAssertNotNil(clientIDHeader, "Expected to return the client id")
        XCTAssertTrue(clientIDHeader?.value.contains(configuration.clientID) ?? false, "Expeccted to use the client id")
    }

    func testRefreshedTokens() async throws {
        let state = AutehenticationDataMock()
        state.accessToken = "abcd"
        persistence.data = try encoder.encode(state)
        let newState = AutehenticationDataMock()
        newState.accessToken = "xyz"
        oauthService.refreshResult = .success(newState)
        oauthService.accessTokenBehavior = .success("xyz")
        _ = try await sut.restoreState()

        let decoded = try persistence.data.map(encoder.decode) as? AutehenticationDataMock
        XCTAssertEqual(
            decoded?.accessToken,
            "xyz",
            "Expected to persist the refreshed state"
        )

        let inputRequest = URLRequest(url: URL(string: "https://example.com")!)
        let resultRequest = try await sut.authenticate(request: inputRequest)
        let authHeader = resultRequest.allHTTPHeaderFields?.first { $0.key.contains("auth-token") }
        XCTAssertEqual(authHeader?.value, "xyz", "Expected to use the refreshed access token for the request")
    }

    // MARK: Private

    private var sut: AuthenticationClientImpl!
    private var oauthService: OAuthServiceMock!
    private var encoder: OAuthStateDataEncoder!
    private var persistence: PersistenceMock!
}

private struct OauthStateEncoderMock: OAuthStateDataEncoder {
    func encode(_ data: any OAuthStateData) throws -> Data {
        guard let data = data as? AutehenticationDataMock else {
            fatalError()
        }
        return try JSONEncoder().encode(data)
    }

    func decode(_ data: Data) throws -> any OAuthStateData {
        try JSONDecoder().decode(AutehenticationDataMock.self, from: data)
    }
}

private final class OAuthServiceMock: OAuthService {
    enum AccessTokenBehavior {
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

    var accessTokenBehavior: AccessTokenBehavior?
    var refreshResult: Result<(any OAuthStateData)?, Error>?

    func getAccessToken(using data: any OAuthStateData) async throws -> (String, any OAuthStateData) {
        guard let behavior = accessTokenBehavior else {
            fatalError()
        }
        return (try behavior.getToken(), try behavior.getStateData() ?? data)
    }
    
    var loginResult: Result<OAuthStateData, Error>?

    func login(on viewController: UIViewController) async throws -> any OAuthStateData {
        try loginResult!.get()
    }

    func refreshIfNeeded(data: any OAuthStateData) async throws -> any OAuthStateData {
        guard let refreshResult = refreshResult else {
            fatalError()
        }
        return try refreshResult.get() ?? data
    }
}

private final class AutehenticationDataMock: Equatable, Codable, OAuthStateData {
    enum Codingkey: String, CodingKey {
        case accessToken
    }

    var accessToken: String? {
        didSet {
            guard oldValue != nil else { return }
        }
    }

    init() { }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Codingkey.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Codingkey.self)
        try container.encode(self.accessToken, forKey: .accessToken)
    }

    var isAuthorized: Bool {
        accessToken != nil
    }

    static func == (lhs: AutehenticationDataMock, rhs: AutehenticationDataMock) -> Bool {
        lhs.accessToken == rhs.accessToken
    }
}

private final class PersistenceMock: Persistence {
    
    var clearCalled = false
    var data: Data?

    func persist(state: Data) throws {
        data = state
    }

    func retrieve() throws -> Data? {
        data
    }

    func clear() throws {
        clearCalled = true
        data = nil
    }
}

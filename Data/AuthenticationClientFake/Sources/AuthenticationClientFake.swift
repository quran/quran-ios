#if QURAN_SYNC

import AuthenticationClient
import Foundation
import MobileSync
import UIKit

public final class AuthenticationClientFake: AuthenticationClient {
    public enum Event: Equatable {
        case readAuthenticationState
        case readLoggedInUser
        case login
        case restoreState
        case logout
        case authenticate
        case getAuthenticationHeaders
    }

    public var authenticationStateValue: AuthenticationState = .notAuthenticated
    public var loggedInUserValue: UserInfo?
    public var loginResult: Result<Void, AuthenticationClientError> = .success(())
    public var restoreStateResult: Result<AuthenticationState, AuthenticationClientError> = .success(.notAuthenticated)
    public var logoutResult: Result<Void, AuthenticationClientError> = .success(())
    public var authenticationHeadersResult: Result<[String: String], AuthenticationClientError> = .success([:])
    public var events: [Event] = []

    public init() {}

    public var authenticationState: AuthenticationState {
        get async {
            events.append(.readAuthenticationState)
            return authenticationStateValue
        }
    }

    public var loggedInUser: UserInfo? {
        get async {
            events.append(.readLoggedInUser)
            return loggedInUserValue
        }
    }

    public func login(on _: UIViewController) async throws(AuthenticationClientError) {
        events.append(.login)
        try loginResult.get()
    }

    public func restoreState() async throws(AuthenticationClientError) -> AuthenticationState {
        events.append(.restoreState)
        return try restoreStateResult.get()
    }

    public func logout() async throws(AuthenticationClientError) {
        events.append(.logout)
        try logoutResult.get()
    }

    public func authenticate(request: URLRequest) async throws(AuthenticationClientError) -> URLRequest {
        events.append(.authenticate)
        return request
    }

    public func getAuthenticationHeaders() async throws(AuthenticationClientError) -> [String: String] {
        events.append(.getAuthenticationHeaders)
        return try authenticationHeadersResult.get()
    }
}

public final class UnavailableAuthenticationClient: AuthenticationClient {
    public init() {}

    public var authenticationState: AuthenticationState {
        get async { .notAuthenticated }
    }

    public var loggedInUser: UserInfo? {
        get async { nil }
    }

    public func login(on _: UIViewController) async throws(AuthenticationClientError) {
        throw .clientIsNotAuthenticated(UnavailableAuthenticationClientError())
    }

    public func restoreState() async throws(AuthenticationClientError) -> AuthenticationState {
        .notAuthenticated
    }

    public func logout() async throws(AuthenticationClientError) {
        throw .clientIsNotAuthenticated(UnavailableAuthenticationClientError())
    }

    public func authenticate(request _: URLRequest) async throws(AuthenticationClientError) -> URLRequest {
        throw .clientIsNotAuthenticated(UnavailableAuthenticationClientError())
    }

    public func getAuthenticationHeaders() async throws(AuthenticationClientError) -> [String: String] {
        throw .clientIsNotAuthenticated(UnavailableAuthenticationClientError())
    }
}

private struct UnavailableAuthenticationClientError: Error {}

#endif

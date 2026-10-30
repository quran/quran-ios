#if QURAN_SYNC

import AuthenticationClient
import Combine
import Foundation
import MobileSync
import UIKit
import Utilities

public final class AuthenticationClientFake: AuthenticationClient {
    public enum Event: Equatable {
        case readAuthenticationState
        case login
        case restoreState
        case logout
        case authenticate
        case getAuthenticationHeaders
    }

    public var authenticationStateValue: AuthenticationState = .notAuthenticated
    public var authenticationStateAfterLogin: AuthenticationState?
    /// The user a successful ``login(on:)`` publishes to ``loggedInUserUpdates``.
    /// Set ``authenticationStateAfterLogin`` to `.authenticated` too, as a real sign-in does.
    public var loggedInUserAfterLogin: MobileSyncUser?
    /// Setting it also publishes the user to ``loggedInUserUpdates``.
    public var loggedInUserValue: MobileSyncUser? {
        didSet { loggedInUserSubject.send(.some(loggedInUserValue)) }
    }

    /// While set, ``restoreState()`` waits for it to finish, like a token refresh waiting on the network.
    public var restoreStateWaitsFor: AsyncStream<Void>?

    public var loginResult: Result<Void, AuthenticationClientError> = .success(())
    public var restoreStateResult: Result<AuthenticationState, AuthenticationClientError> = .success(.notAuthenticated)
    public var logoutResult: Result<Void, AuthenticationClientError> = .success(())
    public var authenticationHeadersResult: Result<[String: String], AuthenticationClientError> = .success([:])
    public var events: [Event] = []

    /// - Parameter restoringSession: Whether MobileSync is still reading the stored session at launch, so
    ///   ``loggedInUserUpdates`` yields nothing until ``loggedInUserValue`` is set.
    public init(restoringSession: Bool = false) {
        loggedInUserSubject = CurrentValueSubject(restoringSession ? .none : .some(nil))
    }

    public var authenticationState: AuthenticationState {
        get async {
            events.append(.readAuthenticationState)
            return authenticationStateValue
        }
    }

    public var authenticationStateChanges: AnyPublisher<AuthenticationState, Never> {
        stateChanges.eraseToAnyPublisher()
    }

    /// ``loggedInUserValue`` now and after every change, without repeats.
    public var loggedInUserUpdates: AnyAsyncSequence<MobileSyncUser?> {
        AnyAsyncSequence(loggedInUserSubject.compactMap { $0 }.removeDuplicates().values())
    }

    /// Ends every current and later ``loggedInUserUpdates`` observation with `error`.
    public func failLoggedInUserUpdates(with error: Error) {
        loggedInUserSubject.send(completion: .failure(error))
    }

    public func login(on _: UIViewController) async throws(AuthenticationClientError) {
        events.append(.login)
        try loginResult.get()
        if let authenticationStateAfterLogin {
            changeState(to: authenticationStateAfterLogin)
        }
        if let loggedInUserAfterLogin {
            loggedInUserValue = loggedInUserAfterLogin
        }
    }

    public func restoreState() async throws(AuthenticationClientError) -> AuthenticationState {
        events.append(.restoreState)
        if let restoreStateWaitsFor {
            for await _ in restoreStateWaitsFor {}
        }
        return try restoreStateResult.get()
    }

    public func logout() async throws(AuthenticationClientError) {
        events.append(.logout)
        try logoutResult.get()
        changeState(to: .notAuthenticated)
        loggedInUserValue = nil
    }

    public func authenticate(request: URLRequest) async throws(AuthenticationClientError) -> URLRequest {
        events.append(.authenticate)
        return request
    }

    public func getAuthenticationHeaders() async throws(AuthenticationClientError) -> [String: String] {
        events.append(.getAuthenticationHeaders)
        return try authenticationHeadersResult.get()
    }

    // MARK: Private

    private let stateChanges = PassthroughSubject<AuthenticationState, Never>()
    /// `.none` until MobileSync has read the stored session.
    private let loggedInUserSubject: CurrentValueSubject<MobileSyncUser??, Error>

    private func changeState(to state: AuthenticationState) {
        guard state != authenticationStateValue else { return }
        authenticationStateValue = state
        stateChanges.send(state)
    }
}

public final class UnavailableAuthenticationClient: AuthenticationClient {
    public init() {}

    public var authenticationState: AuthenticationState {
        get async { .notAuthenticated }
    }

    public var authenticationStateChanges: AnyPublisher<AuthenticationState, Never> {
        Empty().eraseToAnyPublisher()
    }

    public var loggedInUserUpdates: AnyAsyncSequence<MobileSyncUser?> {
        AnyAsyncSequence(AsyncStream { continuation in
            continuation.yield(nil)
            continuation.finish()
        })
    }

    public func login(on _: UIViewController) async throws(AuthenticationClientError) {
        throw .notAuthenticated(underlying: nil)
    }

    public func restoreState() async throws(AuthenticationClientError) -> AuthenticationState {
        .notAuthenticated
    }

    public func logout() async throws(AuthenticationClientError) {
        throw .notAuthenticated(underlying: nil)
    }

    public func authenticate(request _: URLRequest) async throws(AuthenticationClientError) -> URLRequest {
        throw .notAuthenticated(underlying: nil)
    }

    public func getAuthenticationHeaders() async throws(AuthenticationClientError) -> [String: String] {
        throw .notAuthenticated(underlying: nil)
    }
}

#endif

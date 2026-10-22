#if QURAN_SYNC

import Combine
import Foundation
import MobileSync
import UIKit
import VLogging

public final class AuthenticationClientMobileSyncImpl: AuthenticationClient, Sendable {
    // MARK: Lifecycle

    public init(authService: MobileSyncAuthService) {
        self.authService = authService
    }

    // MARK: Public

    public var authenticationState: AuthenticationState {
        authService.isLoggedIn ? .authenticated : .notAuthenticated
    }

    public var authenticationStateChanges: AnyPublisher<AuthenticationState, Never> {
        stateChanges.eraseToAnyPublisher()
    }

    public var loggedInUser: MobileSyncUser? {
        authService.loggedInUser
    }

    public func login(on _: UIViewController) async throws(AuthenticationClientError) {
        let previousState = authenticationState
        defer { reportStateChange(from: previousState) }
        do {
            try await authService.signInWithReauthentication()
        } catch {
            logger.error("Failed to login via mobile sync: \(error)")
            throw AuthenticationClientError(error)
        }
    }

    public func restoreState() async throws(AuthenticationClientError) -> AuthenticationState {
        let previousState = authenticationState
        defer { reportStateChange(from: previousState) }
        do {
            _ = try await authService.refreshAuthentication()
            return authenticationState
        } catch {
            logger.error("Failed to restore mobile sync auth state: \(error)")
            throw AuthenticationClientError(error)
        }
    }

    public func logout() async throws(AuthenticationClientError) {
        let previousState = authenticationState
        defer { reportStateChange(from: previousState) }
        do {
            try await authService.signOut()
        } catch {
            logger.error("Failed to logout via mobile sync: \(error)")
            throw AuthenticationClientError(error)
        }
    }

    public func authenticate(request: URLRequest) async throws(AuthenticationClientError) -> URLRequest {
        let headers = try await getAuthenticationHeaders()
        var request = request
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }

    public func getAuthenticationHeaders() async throws(AuthenticationClientError) -> [String: String] {
        let headers: [String: String]
        do {
            headers = try await authService.authenticationHeaders()
        } catch {
            throw AuthenticationClientError(error)
        }
        guard !headers.isEmpty else {
            throw .notAuthenticated(underlying: nil)
        }
        return headers
    }

    // MARK: Private

    private let authService: MobileSyncAuthService
    private let stateChanges = PassthroughSubject<AuthenticationState, Never>()

    /// Failed operations can change the state too, such as a restore that finds the session revoked.
    private func reportStateChange(from previousState: AuthenticationState) {
        let state = authenticationState
        if state != previousState {
            stateChanges.send(state)
        }
    }
}

private extension AuthenticationClientError {
    init(_ error: MobileSyncAuthenticationError) {
        switch error {
        case .cancelled:
            self = .cancelled
        case let .networkFailure(underlyingError):
            self = .networkFailure(underlying: underlyingError)
        case let .authenticationFailed(underlyingError):
            self = .authenticationFailed(underlying: underlyingError)
        }
    }
}

#endif

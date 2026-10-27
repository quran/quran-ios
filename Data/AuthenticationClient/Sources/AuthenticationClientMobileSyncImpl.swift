#if QURAN_SYNC

import Combine
import Foundation
import MobileSync
import UIKit
import Utilities
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

    public var loggedInUserUpdates: AnyAsyncSequence<MobileSyncUser?> {
        AnyAsyncSequence(AuthenticationErrorSequence(base: authService.loggedInUserUpdates))
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

/// Throws ``AuthenticationClientError`` like the client's other operations, passing cancellation through.
private struct AuthenticationErrorSequence<Base: AsyncSequence>: AsyncSequence {
    struct AsyncIterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator

        mutating func next() async throws -> Base.Element? {
            do {
                return try await base.next()
            } catch let error as CancellationError {
                throw error
            } catch let error as MobileSyncAuthenticationError {
                throw AuthenticationClientError(error)
            } catch {
                throw AuthenticationClientError.authenticationFailed(underlying: error)
            }
        }
    }

    typealias Element = Base.Element

    let base: Base

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator())
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

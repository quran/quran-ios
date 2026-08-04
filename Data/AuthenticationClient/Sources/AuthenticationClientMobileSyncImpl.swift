#if QURAN_SYNC

import Foundation
import MobileSync
import UIKit
import VLogging

public final actor AuthenticationClientMobileSyncImpl: AuthenticationClient {
    // MARK: Lifecycle

    public init(authService: SyncAuthService) {
        self.authService = authService
    }

    // MARK: Public

    public var authenticationState: AuthenticationState {
        authService.isLoggedIn() ? .authenticated : .notAuthenticated
    }

    public var loggedInUser: UserInfo? {
        authService.loggedInUser
    }

    public func login(on _: UIViewController) async throws(AuthenticationClientError) {
        do {
            try await authService.signInWithReauthentication()
        } catch {
            logger.error("Failed to login via mobile sync: \(error)")
            throw AuthenticationClientError(error)
        }
    }

    public func restoreState() async throws(AuthenticationClientError) -> AuthenticationState {
        do {
            _ = try await authService.refreshAuthentication()
            return authenticationState
        } catch {
            logger.error("Failed to restore mobile sync auth state: \(error)")
            throw AuthenticationClientError(error)
        }
    }

    public func logout() async throws(AuthenticationClientError) {
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
        do {
            let headers = try await authService.authenticationHeaders()
            guard !headers.isEmpty else {
                throw AuthenticationClientError.notAuthenticated(underlying: nil)
            }
            return headers
        } catch let error as AuthenticationClientError {
            throw error
        } catch let error as MobileSyncAuthenticationError {
            throw AuthenticationClientError(error)
        } catch {
            throw .authenticationFailed(underlying: error)
        }
    }

    // MARK: Private

    private let authService: SyncAuthService
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

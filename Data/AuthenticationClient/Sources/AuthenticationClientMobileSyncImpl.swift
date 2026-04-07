import Foundation
import MobileSync
import UIKit
import VLogging

public final actor AuthenticationClientMobileSyncImpl: AuthenticationClient {
    // MARK: Lifecycle

    public init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: Public

    public var authenticationState: AuthenticationState {
        authService.isLoggedIn() ? .authenticated : .notAuthenticated
    }

    public var loggedInUser: UserInfo? {
        authService.loggedInUser
    }

    public func login(on _: UIViewController) async throws {
        do {
            try await authService.signIn()
        } catch {
            logger.error("Failed to login via mobile sync: \(error)")
            throw AuthenticationClientError.errorAuthenticating(error)
        }
    }

    public func restoreState() async throws -> AuthenticationState {
        do {
            _ = try await authService.refreshAuthentication()
            return authenticationState
        } catch {
            logger.error("Failed to restore mobile sync auth state: \(error)")
            throw AuthenticationClientError.clientIsNotAuthenticated(error)
        }
    }

    public func logout() async throws {
        do {
            try await authService.signOut()
        } catch {
            logger.error("Failed to logout via mobile sync: \(error)")
            throw AuthenticationClientError.errorAuthenticating(error)
        }
    }

    public func authenticate(request: URLRequest) async throws -> URLRequest {
        let headers = try await getAuthenticationHeaders()
        var request = request
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }

    public func getAuthenticationHeaders() async throws -> [String: String] {
        do {
            return try await authService.authenticationHeaders()
        } catch {
            throw AuthenticationClientError.clientIsNotAuthenticated(error)
        }
    }

    // MARK: Private

    private let authService: AuthService
}

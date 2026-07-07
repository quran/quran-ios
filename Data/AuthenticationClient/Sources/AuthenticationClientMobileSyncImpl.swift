import Foundation
import MobileSync
import UIKit
import VLogging

public final actor AuthenticationClientMobileSyncImpl: AuthenticationClient {
    // MARK: Lifecycle

    public init(authService: SyncAuthService, quranDataService: QuranDataService) {
        self.authService = authService
        self.quranDataService = quranDataService
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
            throw AuthenticationClientError.errorAuthenticating(error)
        }
    }

    public func restoreState() async throws(AuthenticationClientError) -> AuthenticationState {
        do {
            _ = try await authService.refreshAuthentication()
            return authenticationState
        } catch {
            logger.error("Failed to restore mobile sync auth state: \(error)")
            throw AuthenticationClientError.clientIsNotAuthenticated(error)
        }
    }

    public func logout() async throws(AuthenticationClientError) {
        do {
            try await quranDataService.logout(clearLocalData: true)
        } catch {
            logger.error("Failed to logout via mobile sync: \(error)")
            throw AuthenticationClientError.errorAuthenticating(error)
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
            return try await authService.authenticationHeaders()
        } catch {
            throw AuthenticationClientError.clientIsNotAuthenticated(error)
        }
    }

    // MARK: Private

    private let authService: SyncAuthService
    private let quranDataService: QuranDataService
}

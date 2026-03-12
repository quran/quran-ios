import Foundation
import MobileSync
import UIKit
import VLogging

public final actor AuthenticationClientMobileSyncImpl: AuthenticationClient {
    // MARK: Lifecycle

    public init(session: MobileSyncSession) {
        self.session = session
    }

    // MARK: Public

    public var authenticationState: AuthenticationState {
        session.isLoggedIn ? .authenticated : .notAuthenticated
    }

    public func login(on _: UIViewController) async throws {
        do {
            try await session.login()
        } catch {
            logger.error("Failed to login via mobile sync: \(error)")
            throw AuthenticationClientError.errorAuthenticating(error)
        }
    }

    public func restoreState() async throws -> AuthenticationState {
        do {
            return try await session.restoreAuthenticationState()
        } catch {
            logger.error("Failed to restore mobile sync auth state: \(error)")
            throw AuthenticationClientError.clientIsNotAuthenticated(error)
        }
    }

    public func logout() async throws {
        do {
            try await session.logout()
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
            return try await session.getAuthenticationHeaders()
        } catch {
            throw AuthenticationClientError.clientIsNotAuthenticated(error)
        }
    }

    // MARK: Private

    private let session: MobileSyncSession
}

import Foundation
import UIKit
#if QURAN_SYNC
    import KMPNativeCoroutinesAsync
    import MobileSync
    import VLogging
#endif

public final actor AuthenticationClientMobileSyncImpl: AuthenticationClient {
    #if QURAN_SYNC

        public init(session: MobileSyncSession) {
            self.session = session
        }

        public init(configurations: AuthenticationClientConfiguration) {
            session = MobileSyncSession(configurations: configurations)
        }

        // MARK: Public

        public var authenticationState: AuthenticationState {
            guard let authService = session.authService else {
                return .notAuthenticated
            }
            return authService.isLoggedIn() ? .authenticated : .notAuthenticated
        }

        public func login(on _: UIViewController) async throws {
            guard let authService = session.authService else {
                throw AuthenticationClientError.clientIsNotAuthenticated(nil)
            }

            do {
                _ = try await asyncFunction(for: authService.login())
            } catch {
                logger.error("Failed to login via mobile sync: \(error)")
                throw AuthenticationClientError.errorAuthenticating(error)
            }
        }

        public func restoreState() async throws -> AuthenticationState {
            guard let authService = session.authService else {
                return .notAuthenticated
            }

            do {
                _ = try await session.continuePendingLoginIfNeeded()
                _ = try await asyncFunction(for: authService.refreshAccessTokenIfNeeded())
                return authenticationState
            } catch {
                logger.error("Failed to restore mobile sync auth state: \(error)")
                throw AuthenticationClientError.clientIsNotAuthenticated(error)
            }
        }

        public func logout() async throws {
            guard let authService = session.authService else {
                return
            }

            do {
                _ = try await asyncFunction(for: authService.logout())
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
            guard let authService = session.authService else {
                throw AuthenticationClientError.clientIsNotAuthenticated(nil)
            }

            do {
                return try await withCheckedThrowingContinuation { continuation in
                    authService.getAuthHeaders { headers, error in
                        if let error {
                            continuation.resume(throwing: AuthenticationClientError.clientIsNotAuthenticated(error))
                        } else {
                            continuation.resume(returning: headers ?? [:])
                        }
                    }
                }
            } catch let error as AuthenticationClientError {
                throw error
            } catch {
                throw AuthenticationClientError.clientIsNotAuthenticated(error)
            }
        }

        // MARK: Private

        private let session: MobileSyncSession

    #else

        public init(session: MobileSyncSession) {
            if let configurations = session.configurations {
                fallback = AuthenticationClientImpl(configurations: configurations)
            } else {
                fallback = nil
            }
        }

        public init(configurations: AuthenticationClientConfiguration) {
            fallback = AuthenticationClientImpl(configurations: configurations)
        }

        public var authenticationState: AuthenticationState {
            get async {
                guard let fallback else {
                    return .notAuthenticated
                }
                return await fallback.authenticationState
            }
        }

        public func login(on viewController: UIViewController) async throws {
            guard let fallback else {
                throw AuthenticationClientError.clientIsNotAuthenticated(nil)
            }
            try await fallback.login(on: viewController)
        }

        public func restoreState() async throws -> AuthenticationState {
            guard let fallback else {
                return .notAuthenticated
            }
            return try await fallback.restoreState()
        }

        public func logout() async throws {
            guard let fallback else {
                return
            }
            try await fallback.logout()
        }

        public func authenticate(request: URLRequest) async throws -> URLRequest {
            guard let fallback else {
                throw AuthenticationClientError.clientIsNotAuthenticated(nil)
            }
            return try await fallback.authenticate(request: request)
        }

        public func getAuthenticationHeaders() async throws -> [String: String] {
            guard let fallback else {
                throw AuthenticationClientError.clientIsNotAuthenticated(nil)
            }
            return try await fallback.getAuthenticationHeaders()
        }

        private let fallback: AuthenticationClientImpl?

    #endif
}

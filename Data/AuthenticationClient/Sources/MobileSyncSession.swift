import Foundation
#if QURAN_SYNC
    import MobileSync
#endif

public final class MobileSyncSession {
    #if QURAN_SYNC

        public init(configurations: AuthenticationClientConfiguration?) {
            let driverFactory = DriverFactory()
            let environment = Self.makeSynchronizationEnvironment(from: configurations)
            let graph = SharedDependencyGraph.shared.doInit(driverFactory: driverFactory, environment: environment)
            bookmarksRepository = graph.bookmarksRepository

            guard let configurations else {
                authService = nil
                syncService = nil
                oidcAuthRepository = nil
                return
            }

            AuthFlowFactoryProvider.shared.doInitialize()

            let authConfig = Self.makeAuthConfig(from: configurations)
            let json = AuthModule.companion.provideJson()
            let authSettings = AuthModule.companion.provideSettings()
            let authHttpClient = AuthModule.companion.provideHttpClient(json: json, config: authConfig)
            let oidcClient = AuthModule.companion.provideOpenIdConnectClient(config: authConfig, httpClient: authHttpClient)
            let authStorage = AuthStorage(settings: authSettings, json: json)
            let authNetworkDataSource = AuthNetworkDataSource(authConfig: authConfig, httpClient: authHttpClient)
            let logger = KermitLogger.companion.withTag(tag: "quran-ios")
            let oidcAuthRepository = OidcAuthRepository(
                authConfig: authConfig,
                authStorage: authStorage,
                oidcClient: oidcClient,
                networkDataSource: authNetworkDataSource,
                logger: logger
            )
            let authService = AuthService(authRepository: oidcAuthRepository)

            self.authService = authService
            self.oidcAuthRepository = oidcAuthRepository
            syncService = SyncService(
                authService: authService,
                pipeline: graph.syncService.pipelineForIos,
                environment: environment,
                settings: SyncServiceKt.makeSettings()
            )
        }

        // MARK: Public

        public let bookmarksRepository: any BookmarksRepository
        public let authService: AuthService?
        public let syncService: SyncService?

        public func continuePendingLoginIfNeeded() async throws -> Bool {
            guard let oidcAuthRepository else {
                return false
            }

            let canContinue: Bool = try await Self.await { continuation in
                oidcAuthRepository.canContinueLogin { result, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: result?.boolValue ?? false)
                    }
                }
            }

            guard canContinue else {
                return false
            }

            try await Self.awaitVoid { continuation in
                oidcAuthRepository.continueLogin { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }

            return true
        }

        // MARK: Private

        private let oidcAuthRepository: OidcAuthRepository?

        private static func makeAuthConfig(from configurations: AuthenticationClientConfiguration) -> AuthConfig {
            AuthConfig(
                usePreProduction: isPreproductionIssuer(configurations.authorizationIssuerURL),
                clientId: configurations.clientID,
                clientSecret: configurations.clientSecret.isEmpty ? nil : configurations.clientSecret,
                redirectUri: configurations.redirectURL.absoluteString,
                postLogoutRedirectUri: configurations.redirectURL.absoluteString,
                scopes: configurations.scopes
            )
        }

        private static func isPreproductionIssuer(_ url: URL) -> Bool {
            let value = url.absoluteString.lowercased()
            return value.contains("staging") || value.contains("preprod") || value.contains("prelive") || value.contains("dev")
        }

        private static func makeSynchronizationEnvironment(from configurations: AuthenticationClientConfiguration?) -> SynchronizationEnvironment {
            let endpoint = configurations.map { isPreproductionIssuer($0.authorizationIssuerURL) } == true
                ? "https://apis-prelive.quran.foundation/auth"
                : "https://apis.quran.foundation/auth"
            return SynchronizationEnvironment(endPointURL: endpoint)
        }

        private static func await<T>(_ work: @escaping (CheckedContinuation<T, Error>) -> Void) async throws -> T {
            try await withCheckedThrowingContinuation(work)
        }

        private static func awaitVoid(_ work: @escaping (CheckedContinuation<Void, Error>) -> Void) async throws {
            try await withCheckedThrowingContinuation(work)
        }

    #else

        public init(configurations: AuthenticationClientConfiguration?) {
            self.configurations = configurations
        }

        public let configurations: AuthenticationClientConfiguration?

    #endif
}

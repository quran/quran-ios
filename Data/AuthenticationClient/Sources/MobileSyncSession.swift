import Combine
import Foundation
import MobileSync

public final class MobileSyncSession {
    private typealias NativeSuspendCancellation = () -> KotlinUnit
    private typealias NativeSuspend<Result> = (
        @escaping (Result, KotlinUnit) -> KotlinUnit,
        @escaping (Error, KotlinUnit) -> KotlinUnit,
        @escaping (Error, KotlinUnit) -> KotlinUnit
    ) -> NativeSuspendCancellation
    private typealias NativeFlow<Element> = (
        @escaping (Element, @escaping () -> KotlinUnit, KotlinUnit) -> KotlinUnit,
        @escaping (Error?, KotlinUnit) -> KotlinUnit,
        @escaping (Error, KotlinUnit) -> KotlinUnit
    ) -> NativeSuspendCancellation

    // MARK: Lifecycle

    public init(configurations: AuthenticationClientConfiguration) {
        let driverFactory = DriverFactory()
        let environment = Self.makeSynchronizationEnvironment(from: configurations)
        let graph = SharedDependencyGraph.shared.doInit(driverFactory: driverFactory, environment: environment)
        bookmarksRepository = graph.bookmarksRepository

        AuthFlowFactoryProvider.shared.doInitialize()

        let authConfig = Self.makeAuthConfig(from: configurations)
        let json = AuthModule.companion.provideJson()
        let authSettings = AuthModule.companion.provideSettings()
        let authHttpClient = AuthModule.companion.provideHttpClient(json: json, config: authConfig)
        let oidcClient = AuthModule.companion.provideOpenIdConnectClient(config: authConfig, httpClient: authHttpClient)
        let authStorage = AuthStorage(settings: authSettings, json: json)
        let authNetworkDataSource = AuthNetworkDataSource(authConfig: authConfig, httpClient: authHttpClient)
        let logger = KermitLogger.companion.withTag(tag: "quran-ios")
        let authRepository = OidcAuthRepository(
            authConfig: authConfig,
            authStorage: authStorage,
            oidcClient: oidcClient,
            networkDataSource: authNetworkDataSource,
            logger: logger
        )
        let authService = AuthService(authRepository: authRepository)

        self.authRepository = authRepository
        self.authService = authService
        syncService = SyncService(
            authService: authService,
            pipeline: graph.syncService.pipelineForIos,
            environment: environment,
            settings: SyncServiceKt.makeSettings()
        )
    }

    // MARK: Public

    public let bookmarksRepository: any BookmarksRepository
    public let syncService: SyncService

    public var isLoggedIn: Bool {
        authRepository.isLoggedIn()
    }

    public func login() async throws {
        try await Self.awaitIgnoringResult(authService.login())
    }

    public func restoreAuthenticationState() async throws -> AuthenticationState {
        if try await continuePendingLoginIfNeeded() {
            return .authenticated
        }

        try await Self.awaitIgnoringResult(authService.refreshAccessTokenIfNeeded())

        return isLoggedIn ? .authenticated : .notAuthenticated
    }

    public func logout() async throws {
        try await Self.awaitIgnoringResult(authService.logout())
    }

    public func getAuthenticationHeaders() async throws -> [String: String] {
        try await withCheckedThrowingContinuation { continuation in
            authRepository.getAuthHeaders { headers, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: headers ?? [:])
                }
            }
        }
    }

    public func bookmarksPublisher() -> AnyPublisher<[Bookmark], Never> {
        Deferred {
            let subject = CurrentValueSubject<[Bookmark], Never>([])
            let cancel = self.observeBookmarks(
                onValue: { subject.send($0) },
                onCompletion: {
                    if $0 != nil {
                        subject.send([])
                    }
                    subject.send(completion: .finished)
                }
            )
            return subject
                .handleEvents(receiveCancel: { _ = cancel() })
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    public func addPageBookmark(_ page: Int) async throws {
        _ = try await Self.await(syncService.addBookmark(page: Int32(page)))
        syncService.triggerSync()
    }

    public func removePageBookmark(_ page: Int) async throws {
        let bookmarks = try await allBookmarks()
        guard let bookmark = Self.pageBookmark(in: bookmarks, page: page) else {
            return
        }

        _ = try await Self.await(syncService.deleteBookmark(bookmark: bookmark))
        syncService.triggerSync()
    }

    public func removeAllPageBookmarks() async throws {
        let bookmarks = try await allBookmarks()
        let pageBookmarks = bookmarks.compactMap { $0 as? Bookmark.PageBookmark }

        for bookmark in pageBookmarks {
            _ = try await Self.await(syncService.deleteBookmark(bookmark: bookmark))
        }

        syncService.triggerSync()
    }

    // MARK: Private

    private let authRepository: OidcAuthRepository
    private let authService: AuthService

    private static func pageBookmark(in bookmarks: [Bookmark], page: Int) -> Bookmark.PageBookmark? {
        bookmarks
            .compactMap { $0 as? Bookmark.PageBookmark }
            .first { Int($0.page) == page }
    }

    private static func await<Result>(_ work: @escaping NativeSuspend<Result>) async throws -> Result {
        try await withCheckedThrowingContinuation { continuation in
            _ = work(
                { result, _ in
                    continuation.resume(returning: result)
                    return KotlinUnit.shared
                },
                { error, _ in
                    continuation.resume(throwing: error)
                    return KotlinUnit.shared
                },
                { error, _ in
                    continuation.resume(throwing: error)
                    return KotlinUnit.shared
                }
            )
        }
    }

    private static func awaitIgnoringResult<Result>(_ work: @escaping NativeSuspend<Result>) async throws {
        _ = try await Self.await(work)
    }

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

    private static func makeSynchronizationEnvironment(from configurations: AuthenticationClientConfiguration) -> SynchronizationEnvironment {
        let endpoint = isPreproductionIssuer(configurations.authorizationIssuerURL)
            ? "https://apis-prelive.quran.foundation/auth"
            : "https://apis.quran.foundation/auth"
        return SynchronizationEnvironment(endPointURL: endpoint)
    }

    private func continuePendingLoginIfNeeded() async throws -> Bool {
        let canContinue: Bool = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            authRepository.canContinueLogin { result, error in
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

        let _: Void = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            authRepository.continueLogin { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        return true
    }

    private func allBookmarks() async throws -> [Bookmark] {
        try await Self.await(bookmarksRepository.getAllBookmarks())
    }

    private func observeBookmarks(
        onValue: @escaping ([Bookmark]) -> Void,
        onCompletion: @escaping (Error?) -> Void
    ) -> NativeSuspendCancellation {
        let nativeFlow = syncService.bookmarks
        return nativeFlow(
            { bookmarks, next, _ in
                onValue(bookmarks)
                return next()
            },
            { error, _ in
                onCompletion(error)
                return KotlinUnit.shared
            },
            { error, _ in
                onCompletion(error)
                return KotlinUnit.shared
            }
        )
    }
}

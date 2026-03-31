import Combine
import Foundation
import MobileSync

public final class MobileSyncSession {
    // MARK: Lifecycle

    public init(clientID: String, clientSecret: String?, usePreProduction: Bool) {
        let synchronizationEnvironment = Self.makeSynchronizationEnvironment(usePreProduction: usePreProduction)
        let authEnvironment: AuthEnvironment = usePreProduction ? .prelive : .production

        AuthFlowFactoryProvider.shared.doInitialize()

        let driverFactory = DriverFactory()
        let graph = SharedDependencyGraph.shared.doInit(
            driverFactory: driverFactory,
            environment: synchronizationEnvironment,
            authEnvironment: authEnvironment
        )

        let authConfig = AuthConfig(
            environment: authEnvironment,
            clientId: clientID,
            clientSecret: clientSecret,
            redirectUri: Self.redirectURI,
            postLogoutRedirectUri: Self.redirectURI,
            scopes: Self.scopes
        )
        let json = AuthModule.companion.provideJson()
        let settings = AuthModule.companion.provideSettings()
        let httpClient = AuthModule.companion.provideHttpClient(json: json, config: authConfig)
        let oidcClient = AuthModule.companion.provideOpenIdConnectClient(
            config: authConfig,
            httpClient: httpClient
        )
        let authStorage = AuthStorage(settings: settings, json: json)
        let authNetworkDataSource = AuthNetworkDataSource(
            authConfig: authConfig,
            httpClient: httpClient
        )
        let logger = KermitLogger.companion.withTag(tag: "quran-ios")
        let authRepository = OidcAuthRepository(
            authConfig: authConfig,
            authStorage: authStorage,
            oidcClient: oidcClient,
            networkDataSource: authNetworkDataSource,
            logger: logger
        )
        let authService = AuthService(authRepository: authRepository)

        self.authService = authService
        syncService = SyncService(
            authService: authService,
            pipeline: graph.syncService.pipelineForIos,
            environment: synchronizationEnvironment,
            settings: SyncServiceKt.makeSettings()
        )
    }

    // MARK: Public

    public let syncService: SyncService

    public var isLoggedIn: Bool {
        authService.isLoggedIn()
    }

    public func login() async throws {
        try await authService.signIn()
    }

    public func restoreAuthenticationState() async throws -> AuthenticationState {
        _ = try await authService.refreshAuthentication()

        return isLoggedIn ? .authenticated : .notAuthenticated
    }

    public func logout() async throws {
        try await authService.signOut()
    }

    public func getAuthenticationHeaders() async throws -> [String: String] {
        try await authService.authenticationHeaders()
    }

    public func bookmarksPublisher() -> AnyPublisher<[Bookmark], Never> {
        startBookmarksObservationIfNeeded()
        return bookmarksSubject.eraseToAnyPublisher()
    }

    public func addPageBookmark(_ page: Int) async throws {
        _ = try await syncService.addPageBookmark(Int32(page))
    }

    public func removePageBookmark(_ page: Int) async throws {
        let bookmarks = try await currentBookmarks()
        guard let bookmark = Self.pageBookmark(in: bookmarks, page: page) else {
            return
        }

        try await syncService.removeBookmark(bookmark)
    }

    public func removeAllPageBookmarks() async throws {
        let bookmarks = try await currentBookmarks()
        let pageBookmarks = bookmarks.compactMap { $0 as? Bookmark.PageBookmark }

        for bookmark in pageBookmarks {
            try await syncService.removeBookmark(bookmark)
        }
    }

    // MARK: Private

    private func startBookmarksObservationIfNeeded() {
        guard bookmarksObservationTask == nil else {
            return
        }

        bookmarksObservationTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                for try await bookmarks in syncService.bookmarksSequence() {
                    bookmarksSubject.send(bookmarks)
                }
            } catch {
                // Ignore errors
            }
        }
    }

    private let authService: AuthService
    private let bookmarksSubject = CurrentValueSubject<[Bookmark], Never>([])
    private var bookmarksObservationTask: Task<Void, Never>?

    private static func pageBookmark(in bookmarks: [Bookmark], page: Int) -> Bookmark.PageBookmark? {
        bookmarks
            .compactMap { $0 as? Bookmark.PageBookmark }
            .first { Int($0.page) == page }
    }

    private static func makeSynchronizationEnvironment(usePreProduction: Bool) -> SynchronizationEnvironment {
        let endpoint = usePreProduction
            ? "https://apis-prelive.quran.foundation/auth"
            : "https://apis.quran.foundation/auth"
        return SynchronizationEnvironment(endPointURL: endpoint)
    }

    @MainActor
    private func currentBookmarks() async throws -> [Bookmark] {
        for try await bookmarks in syncService.bookmarksSequence() {
            return bookmarks
        }

        return []
    }

    private static let redirectURI = "com.quran.oauth://callback"
    private static let scopes = [
        "openid",
        "offline_access",
        "content",
        "user",
        "bookmark",
        "sync",
        "collection",
        "reading_session",
        "preference",
        "note",
    ]
}

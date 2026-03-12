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

    // MARK: Lifecycle

    public init(clientID: String, clientSecret: String?, usePreProduction: Bool) {
        let environment = Self.makeSynchronizationEnvironment(usePreProduction: usePreProduction)
        let configuration = MobileSyncClientConfiguration(
            clientId: clientID,
            clientSecret: clientSecret,
            usePreProduction: usePreProduction
        )
        let container = AppContainer(configuration: configuration, environment: environment)
        self.container = container
        syncViewModel = SyncViewModel(container: container)
        syncService = container.syncService
        bookmarksRepository = container.bookmarksRepository
    }

    // MARK: Public

    public let bookmarksRepository: any BookmarksRepository
    public let syncService: SyncService

    public var isLoggedIn: Bool {
        syncViewModel.isLoggedIn()
    }

    public func login() async throws {
        try await syncViewModel.login()
    }

    public func restoreAuthenticationState() async throws -> AuthenticationState {
        _ = try await syncViewModel.refreshAccessTokenIfNeeded()

        return isLoggedIn ? .authenticated : .notAuthenticated
    }

    public func logout() async throws {
        try await syncViewModel.logout()
    }

    public func getAuthenticationHeaders() async throws -> [String: String] {
        try await syncViewModel.getAuthHeaders()
    }

    public func bookmarksPublisher() -> AnyPublisher<[Bookmark], Never> {
        let subject = CurrentValueSubject<[Bookmark], Never>([])
        let task = Task {
            do {
                for try await bookmarks in syncViewModel.bookmarksSequence() {
                    subject.send(bookmarks)
                }
            } catch {
                // Ignore errors
            }
            subject.send(completion: .finished)
        }
        return subject
            .handleEvents(receiveCancel: { task.cancel() })
            .eraseToAnyPublisher()
    }

    public func addPageBookmark(_ page: Int) async throws {
        _ = try await syncViewModel.addBookmark(page: Int32(page))
        syncViewModel.triggerSync()
    }

    public func removePageBookmark(_ page: Int) async throws {
        let bookmarks = try await allBookmarks()
        guard let bookmark = Self.pageBookmark(in: bookmarks, page: page) else {
            return
        }

        try await syncViewModel.deleteBookmark(bookmark: bookmark)
        syncViewModel.triggerSync()
    }

    public func removeAllPageBookmarks() async throws {
        let bookmarks = try await allBookmarks()
        let pageBookmarks = bookmarks.compactMap { $0 as? Bookmark.PageBookmark }

        for bookmark in pageBookmarks {
            try await syncViewModel.deleteBookmark(bookmark: bookmark)
        }

        syncViewModel.triggerSync()
    }

    // MARK: Private

    private let container: AppContainer
    private let syncViewModel: SyncViewModel

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

    private static func makeSynchronizationEnvironment(usePreProduction: Bool) -> SynchronizationEnvironment {
        let endpoint = usePreProduction
            ? "https://apis-prelive.quran.foundation/auth"
            : "https://apis.quran.foundation/auth"
        return SynchronizationEnvironment(endPointURL: endpoint)
    }

    private func allBookmarks() async throws -> [Bookmark] {
        try await Self.await(bookmarksRepository.getAllBookmarks())
    }
}

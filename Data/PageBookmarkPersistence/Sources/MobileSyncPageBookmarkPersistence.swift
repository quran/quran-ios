import Combine
import MobileSync

public struct MobileSyncPageBookmarkPersistence: PageBookmarkPersistence, @unchecked Sendable {
    // MARK: Lifecycle

    public init(syncService: SyncService) {
        self.syncService = syncService
    }

    // MARK: Public

    public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        let subject = CurrentValueSubject<[PageBookmarkPersistenceModel], Never>([])
        let task = Task { @MainActor in
            do {
                for try await bookmarks in syncService.bookmarksSequence() {
                    let persistenceModels = bookmarks
                        .compactMap(Self.persistenceModel(from:))
                        .sorted { $0.creationDate > $1.creationDate }
                    subject.send(persistenceModels)
                }
            } catch {
                // Ignore errors
            }
        }

        return subject
            .handleEvents(receiveCancel: { task.cancel() })
            .eraseToAnyPublisher()
    }

    public func insertPageBookmark(_ page: Int) async throws {
        _ = try await syncService.addPageBookmark(Int32(page))
    }

    public func removePageBookmark(_ page: Int) async throws {
        let bookmarks = try await bookmarks()
        guard let bookmark = Self.pageBookmark(in: bookmarks, page: page) else {
            return
        }

        try await syncService.removeBookmark(bookmark)
    }

    public func removeAllPageBookmarks() async throws {
        let pageBookmarks = try await bookmarks().compactMap { $0 as? Bookmark.PageBookmark }

        for bookmark in pageBookmarks {
            try await syncService.removeBookmark(bookmark)
        }
    }

    // MARK: Private

    private let syncService: SyncService

    private static func pageBookmark(in bookmarks: [Bookmark], page: Int) -> Bookmark.PageBookmark? {
        bookmarks
            .compactMap { $0 as? Bookmark.PageBookmark }
            .first { Int($0.page) == page }
    }

    private static func persistenceModel(from bookmark: Bookmark) -> PageBookmarkPersistenceModel? {
        guard let bookmark = bookmark as? Bookmark.PageBookmark else {
            return nil
        }
        return PageBookmarkPersistenceModel(page: Int(bookmark.page), creationDate: bookmark.lastUpdated)
    }

    @MainActor
    private func bookmarks() async throws -> [Bookmark] {
        for try await bookmarks in syncService.bookmarksSequence() {
            return bookmarks
        }

        return []
    }
}

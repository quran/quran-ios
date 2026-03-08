#if QURAN_SYNC
    import AuthenticationClient
    import Combine
    import MobileSync

    public struct MobileSyncPageBookmarkPersistence: PageBookmarkPersistence {
        // MARK: Lifecycle

        public init(session: MobileSyncSession) {
            self.session = session
            pageBookmarksPublisher = session.bookmarksPublisher()
                .map { bookmarks in
                    bookmarks
                        .compactMap(Self.persistenceModel(from:))
                        .sorted { $0.creationDate > $1.creationDate }
                }
                .eraseToAnyPublisher()
        }

        // MARK: Public

        public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
            pageBookmarksPublisher
        }

        public func insertPageBookmark(_ page: Int) async throws {
            try await session.addPageBookmark(page)
        }

        public func removePageBookmark(_ page: Int) async throws {
            try await session.removePageBookmark(page)
        }

        public func removeAllPageBookmarks() async throws {
            try await session.removeAllPageBookmarks()
        }

        // MARK: Private

        private let session: MobileSyncSession
        private let pageBookmarksPublisher: AnyPublisher<[PageBookmarkPersistenceModel], Never>

        private static func persistenceModel(from bookmark: Bookmark) -> PageBookmarkPersistenceModel? {
            guard let bookmark = bookmark as? Bookmark.PageBookmark else {
                return nil
            }
            return PageBookmarkPersistenceModel(page: Int(bookmark.page), creationDate: bookmark.lastUpdated)
        }
    }
#endif

import AuthenticationClient
import Combine
import CoreDataPersistence
import Foundation
#if QURAN_SYNC
    import CoreData
    import CoreDataModel
    import KMPNativeCoroutinesAsync
    import MobileSync
    import VLogging
#endif
public final class MobileSyncPageBookmarkPersistence: PageBookmarkPersistence {
    #if QURAN_SYNC

        public init(session: MobileSyncSession, legacyStack: CoreDataStack? = nil) {
            bookmarksRepository = session.bookmarksRepository
            syncService = session.syncService
            legacyContext = legacyStack?.newBackgroundContext()
            observationTask = Task { [weak self] in
                await self?.bootstrap()
            }
        }

        public convenience init(configurations: AuthenticationClientConfiguration? = nil, legacyStack: CoreDataStack? = nil) {
            self.init(session: MobileSyncSession(configurations: configurations), legacyStack: legacyStack)
        }

        deinit {
            observationTask?.cancel()
        }

        // MARK: Public

        public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
            subject.eraseToAnyPublisher()
        }

        public func insertPageBookmark(_ page: Int) async throws {
            if let syncService {
                _ = try await asyncFunction(for: syncService.addBookmark(page: Int32(page)))
                syncService.triggerSync()
            } else {
                _ = try await asyncFunction(for: bookmarksRepository.addBookmark(page: Int32(page)))
            }
        }

        public func removePageBookmark(_ page: Int) async throws {
            if let syncService {
                let bookmarks = try await asyncFunction(for: bookmarksRepository.getAllBookmarks())
                guard let bookmark = Self.pageBookmark(in: bookmarks, page: page) else {
                    return
                }
                _ = try await asyncFunction(for: syncService.deleteBookmark(bookmark: bookmark))
                syncService.triggerSync()
            } else {
                _ = try await asyncFunction(for: bookmarksRepository.deleteBookmark(page: Int32(page)))
            }
        }

        public func removeAllPageBookmarks() async throws {
            let bookmarks = try await asyncFunction(for: bookmarksRepository.getAllBookmarks())
            let pageBookmarks = bookmarks.compactMap { $0 as? Bookmark.PageBookmark }

            for bookmark in pageBookmarks {
                if let syncService {
                    _ = try await asyncFunction(for: syncService.deleteBookmark(bookmark: bookmark))
                } else {
                    _ = try await asyncFunction(for: bookmarksRepository.deleteBookmark(page: bookmark.page))
                }
            }

            syncService?.triggerSync()
        }

        // MARK: Private

        private let bookmarksRepository: any BookmarksRepository
        private let syncService: SyncService?
        private let legacyContext: NSManagedObjectContext?
        private let subject = CurrentValueSubject<[PageBookmarkPersistenceModel], Never>([])
        private var observationTask: Task<Void, Never>?

        private func bootstrap() async {
            await migrateLegacyBookmarksIfNeeded()
            await observeBookmarks()
        }

        private func observeBookmarks() async {
            do {
                for try await bookmarks in bookmarksRepository.bookmarksSequence() {
                    let models = bookmarks
                        .compactMap(Self.persistenceModel(from:))
                        .sorted { $0.creationDate > $1.creationDate }
                    subject.send(models)
                }
            } catch {
                logger.error("Failed to observe mobile sync bookmarks: \(error)")
                subject.send([])
            }
        }

        private func migrateLegacyBookmarksIfNeeded() async {
            guard let legacyContext else {
                return
            }

            do {
                let existing = try await asyncFunction(for: bookmarksRepository.getAllBookmarks())
                guard existing.isEmpty else {
                    return
                }

                let request: NSFetchRequest<MO_PageBookmark> = MO_PageBookmark.fetchRequest()
                let legacyBookmarks = try await legacyContext.perform { context in
                    let rows = try context.fetch(request)
                    return rows.map(\.page)
                }

                guard !legacyBookmarks.isEmpty else {
                    return
                }

                let migrations = legacyBookmarks.map { BookmarkMigration.Page(page: Int32($0)) }
                _ = try await asyncFunction(for: bookmarksRepository.migrateBookmarks(bookmarks: migrations))
                syncService?.triggerSync()
            } catch {
                logger.error("Failed to migrate legacy page bookmarks to mobile sync: \(error)")
            }
        }

        private static func persistenceModel(from bookmark: Bookmark) -> PageBookmarkPersistenceModel? {
            guard let bookmark = bookmark as? Bookmark.PageBookmark else {
                return nil
            }
            return PageBookmarkPersistenceModel(page: Int(bookmark.page), creationDate: bookmark.lastUpdated)
        }

        private static func pageBookmark(in bookmarks: [Bookmark], page: Int) -> Bookmark.PageBookmark? {
            bookmarks
                .compactMap { $0 as? Bookmark.PageBookmark }
                .first { Int($0.page) == page }
        }

    #else

        public init(session _: MobileSyncSession, legacyStack: CoreDataStack? = nil) {
            guard let legacyStack else {
                preconditionFailure("CoreDataStack is required when Quran sync is disabled")
            }
            fallback = CoreDataPageBookmarkPersistence(stack: legacyStack)
        }

        public convenience init(configurations: AuthenticationClientConfiguration? = nil, legacyStack: CoreDataStack? = nil) {
            self.init(session: MobileSyncSession(configurations: configurations), legacyStack: legacyStack)
        }

        public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
            fallback.pageBookmarks()
        }

        public func insertPageBookmark(_ page: Int) async throws {
            try await fallback.insertPageBookmark(page)
        }

        public func removePageBookmark(_ page: Int) async throws {
            try await fallback.removePageBookmark(page)
        }

        public func removeAllPageBookmarks() async throws {
            try await fallback.removeAllPageBookmarks()
        }

        private let fallback: CoreDataPageBookmarkPersistence

    #endif
}

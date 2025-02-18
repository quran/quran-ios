//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 18/02/2025.
//

import Foundation
import Combine
import SyncedPageBookmarkPersistence
import PageBookmarkMutationsPersistence
import VLogging

// TODO: Might need to rename this.
public final class SynchronizedPageBookmarkPersistence: PageBookmarkPersistence {
    private let syncedBookmarksPersistence: SyncedPageBookmarkPersistence
    private let bookmarkMutationsPersistence: PageBookmarkMutationsPersistence

    init(syncedBookmarksPersistence: SyncedPageBookmarkPersistence,
         bookmarkMutationsPersistence: PageBookmarkMutationsPersistence) {
        self.syncedBookmarksPersistence = syncedBookmarksPersistence
        self.bookmarkMutationsPersistence = bookmarkMutationsPersistence
    }

    public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        do {
            return try syncedBookmarksPersistence.pageBookmarksPublisher()
                .map{ $0.map{ PageBookmarkPersistenceModel(remoteID: $0.remoteID,
                                                           page: $0.page,
                                                           creationDate: $0.creationDate)} }
                .eraseToAnyPublisher()
        }
        catch {
            logger.error("Failed to create a publisher for synced page bookmarks: \(error)")
            return Empty<[PageBookmarkPersistenceModel], Never>().eraseToAnyPublisher()
        }
    }

    public func insertPageBookmark(_ page: Int) async throws {
        fatalError()
    }
    
    public func removePageBookmark(_ page: Int) async throws {
        fatalError()
    }
}

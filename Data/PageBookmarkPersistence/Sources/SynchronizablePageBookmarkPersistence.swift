//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 18/02/2025.
//

import Foundation
import Combine
import SyncedPageBookmarkPersistence
import MutatedPageBookmarkPersistence
import VLogging

/// The repository that tracks the state of synchronized and unsynchronized bookmarks.
public struct SynchronizablePageBookmarkPersistence: PageBookmarkPersistence {
    private let syncedBookmarksPersistence: SyncedPageBookmarkPersistence
    private let bookmarkMutationsPersistence: MutatedPageBookmarkPersistence

    init(syncedBookmarksPersistence: SyncedPageBookmarkPersistence,
         bookmarkMutationsPersistence: MutatedPageBookmarkPersistence) {
        self.syncedBookmarksPersistence = syncedBookmarksPersistence
        self.bookmarkMutationsPersistence = bookmarkMutationsPersistence
    }

    public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        let syncedPublisher = syncedPageBookmarksPublisher()
        let mutatedPublisher = mutatedPageBookmarksPublisher()

        return syncedPublisher
            .combineLatest(mutatedPublisher)
            .map{ syncedBookmarks, mutatedBookmarks in
                let mutatedPages = Set(mutatedBookmarks.map(\.page))

                let uneditedSynced = syncedBookmarks.filter{ !mutatedPages.contains($0.page) }
                let newBookmarks = mutatedBookmarks.filter{ $0.mutation != .deleted }
                    .map{ PageBookmarkPersistenceModel(page: $0.page, creationDate: $0.modificationDate) }

                return uneditedSynced + newBookmarks
            }
            .eraseToAnyPublisher()
    }

    private func syncedPageBookmarksPublisher() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        do {
            return try syncedBookmarksPersistence.pageBookmarksPublisher().map{
                $0.map{ PageBookmarkPersistenceModel(remoteID: $0.remoteID,
                                                     page: $0.page,
                                                     creationDate: $0.creationDate)
                }
            }
            .eraseToAnyPublisher()
        }
        catch {
            logger.error("Failed to create a publisher for synced page bookmarks: \(error)")
            return Empty<[PageBookmarkPersistenceModel], Never>().eraseToAnyPublisher()
        }
    }

    private func mutatedPageBookmarksPublisher() -> AnyPublisher<[MutatedPageBookmarkModel], Never> {
        do {
            return try bookmarkMutationsPersistence.bookmarksPublisher()
                .eraseToAnyPublisher()
        }
        catch {
            logger.error("Failed to create a publisher for mutated apge bookmarks: \(error)")
            return Empty<[MutatedPageBookmarkModel], Never>().eraseToAnyPublisher()
        }
    }

    public func insertPageBookmark(_ page: Int) async throws {
        let remote = try await syncedBookmarksPersistence.bookmark(page: page)
        let mutations = try await bookmarkMutationsPersistence.bookmarkMutations(page: page)

        let hasRemote = remote != nil
        let remoteDeleted = mutations.filter{ $0.mutation == .deleted }.count > 0
        let createdLocally = mutations.filter{ $0.mutation == .created }.count > 0

        guard !createdLocally && ( !hasRemote || remoteDeleted ) else {
            throw PageBookmarkPersistenceError.bookmarkAlreadyExists
        }

        do {
            try await bookmarkMutationsPersistence.createBookmark(page: page)
        } catch {
            logger.error("Failed to create a bookmark locally: \(error). Rethrown.")
            throw error
        }
    }
    
    public func removePageBookmark(_ page: Int) async throws {
        do {
            // Will rely on MutatedPageBookmarkPersistence to handle its internal state.
            if let syncedBookmark = try await syncedBookmarksPersistence.bookmark(page: page) {
                try await bookmarkMutationsPersistence.removeBookmark(page: page, remoteID: syncedBookmark.remoteID)
            } else {
                try await bookmarkMutationsPersistence.removeBookmark(page: page, remoteID: nil)
            }
        } catch {
            logger.error("Failed to remove a bookmark locally: \(error). Rethrown.")
            throw error
        }
    }
}

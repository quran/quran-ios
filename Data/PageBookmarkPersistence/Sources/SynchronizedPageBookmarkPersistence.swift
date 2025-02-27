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

// TODO: Might need to rename this.
public struct SynchronizedPageBookmarkPersistence: PageBookmarkPersistence {
    private let syncedBookmarksPersistence: SyncedPageBookmarkPersistence
    private let bookmarkMutationsPersistence: MutatedPageBookmarkPersistence

    init(syncedBookmarksPersistence: SyncedPageBookmarkPersistence,
         bookmarkMutationsPersistence: MutatedPageBookmarkPersistence) {
        self.syncedBookmarksPersistence = syncedBookmarksPersistence
        self.bookmarkMutationsPersistence = bookmarkMutationsPersistence
    }

    public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        let syncedPublisher: AnyPublisher<[PageBookmarkPersistenceModel], Never>
        do {
            syncedPublisher = try syncedBookmarksPersistence.pageBookmarksPublisher()
                .map{ $0.map{ PageBookmarkPersistenceModel(remoteID: $0.remoteID,
                                                           page: $0.page,
                                                           creationDate: $0.creationDate)
                }}
                .eraseToAnyPublisher()
        }
        catch {
            logger.error("Failed to create a publisher for synced page bookmarks: \(error)")
            syncedPublisher = Empty<[PageBookmarkPersistenceModel], Never>().eraseToAnyPublisher()
        }

        let mutatedPublisher: AnyPublisher<[MutatedPageBookmarkModel], Never>
        do {
            mutatedPublisher = try bookmarkMutationsPersistence.bookmarksPublisher()
                .eraseToAnyPublisher()
        }
        catch {
            logger.error("Failed to create a publisher for mutated apge bookmarks: \(error)")
            mutatedPublisher = Empty<[MutatedPageBookmarkModel], Never>().eraseToAnyPublisher()
        }

        return syncedPublisher
            .combineLatest(mutatedPublisher)
            .map{ syncedBookmarks, mutatedBookmarks in
                // TODO: Replace with a set!
                let mutationByPage = mutatedBookmarks.reduce(into: [Int:MutatedPageBookmarkModel]()) { partialResult, bookmark in
                    partialResult[bookmark.page] = bookmark
                }

                let uneditedSynced = syncedBookmarks.filter{ mutationByPage[$0.page] == nil }
                let newBookmarks = mutatedBookmarks.filter{ $0.mutation != .deleted }
                    .map{ PageBookmarkPersistenceModel(page: $0.page, creationDate: $0.modificationDate) }

                return uneditedSynced + newBookmarks
            }
            .eraseToAnyPublisher()
    }

    public func insertPageBookmark(_ page: Int) async throws {
        let remote = try await syncedBookmarksPersistence.bookmark(page: page)
        let mutations = try await bookmarkMutationsPersistence.bookmarkMutations(page: page)

        let hasRemote = remote != nil
        let remoteDeleted = mutations.filter{ $0.mutation == .deleted }.count > 0
        let createdLocally = mutations.filter{ $0.mutation == .created }.count > 0

        guard !createdLocally && ( !hasRemote || remoteDeleted ) else {
            // TODO: Throw a specific error!
            throw MutatedPageBookmarkPersistenceError.bookmarkAlreadyExists(page: page)
        }

        do {
            try await bookmarkMutationsPersistence.createBookmark(page: page)
        } catch {
            logger.error("Failed to create a bookmark mutation: \(error)")
            throw error
        }
    }
    
    public func removePageBookmark(_ page: Int) async throws {
        let mutations = try await bookmarkMutationsPersistence.bookmarkMutations(page: page)
        if let syncedBookmark = try await syncedBookmarksPersistence.bookmark(page: page) {
            try await bookmarkMutationsPersistence.removeBookmark(page: page, remoteID: syncedBookmark.remoteID)
        } else {
            try await bookmarkMutationsPersistence.removeBookmark(page: page, remoteID: nil)
        }
    }
}

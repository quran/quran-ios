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
public struct SynchronizedPageBookmarkPersistence: PageBookmarkPersistence {
    private let syncedBookmarksPersistence: SyncedPageBookmarkPersistence
    private let bookmarkMutationsPersistence: PageBookmarkMutationsPersistence

    init(syncedBookmarksPersistence: SyncedPageBookmarkPersistence,
         bookmarkMutationsPersistence: PageBookmarkMutationsPersistence) {
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
        fatalError()
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

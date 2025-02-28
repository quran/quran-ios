//
//  MutatedPageBookmarkPersistence.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 10/02/2025.
//

import Combine
import Foundation

public enum MutatedPageBookmarkPersistenceError: Error {
    case bookmarkAlreadyExists(page: Int)
    case illegalState(reason: String, page: Int)
}

/// Provides access for a mutable page bookmark persistence.
///
/// This persistence layer is aware of the difference between downstream and upstream-synced bookmarks. It can mark
/// a mutation record for an upstream-synced bookmark, while providing access to create and remove local-unsynced
/// bookmarks. If used in an unconnected state, this persistence can be can be seen as an local bookmarks persistence,
/// without reference to upstream resources.
///
/// The repository guarantees that it can only hold a single *created* bookmark for a page. It may hold a record of a
/// deleted upstream bookmark for a page holding a record for a created local unsynced bookmark. It's the responsibility
/// of the client of this persistence to guarantee any further data requirements with the upstream resources.
///
/// See `MutatedPageBookmarkModel` for more information on the state of the returend objects.
public protocol MutatedPageBookmarkPersistence {
    func bookmarksPublisher() throws -> AnyPublisher<[MutatedPageBookmarkModel], Never>

    func bookmarks() async throws -> [MutatedPageBookmarkModel]

    func bookmarkMutations(page: Int) async throws -> [MutatedPageBookmarkModel]

    /// Creates a new local bookmark for the given page.
    ///
    /// - throws `MutatedPageBookmarkPersistenceError.bookmarkAlreadyExists`
    func createBookmark(page: Int) async throws

    /// Signals the removal of the bookmark for the given page.
    ///
    /// If `remoteID` is given, this marks the record for deletion on the associated upstream resource.
    /// If `remoteID` is `nil`, this will remove the records of the bookmark of the given page.
    ///
    /// - throws `MutatedPageBookmarkPersistenceError.illegalState` if
    /// `remoteID` is nil, and there's no local  bookmark for that page.
    func removeBookmark(page: Int, remoteID: String?) async throws

    /// Clears all records.
    ///
    /// Should only be called after a sync operation with the upstream source is done.
    func clear() async throws
}

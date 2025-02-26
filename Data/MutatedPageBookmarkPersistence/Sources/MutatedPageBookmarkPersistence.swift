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

public protocol MutatedPageBookmarkPersistence {
    func bookmarksPublisher() throws -> AnyPublisher<[MutatedPageBookmarkModel], Never>

    func bookmarks() async throws -> [MutatedPageBookmarkModel]

    func bookmarkMutations(page: Int) async throws -> [MutatedPageBookmarkModel]

    func createBookmark(page: Int) async throws

    func removeBookmark(page: Int, remoteID: String?) async throws

    func clear() async throws
}

//
//  PageBookmarkMutationsPersistence.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 10/02/2025.
//

import Combine
import Foundation

public enum PageBookmarkMutationsPersistenceError: Error {
    case bookmarkAlreadyExists(page: Int)
    case illegalState(reason: String, page: Int)
}

public protocol PageBookmarkMutationsPersistence {
    func bookmarksPublisher() throws -> AnyPublisher<[MutatedPageBookmarkModel], Never>

    func bookmarks() async throws -> [MutatedPageBookmarkModel]

    func createBookmark(page: Int) async throws

    func removeBookmark(_ bookmark: MutatedPageBookmarkModel) async throws

    func clear() async throws
}

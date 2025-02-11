//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 10/02/2025.
//

import Foundation
import Combine

struct GRDBPageBookmarkMutationsPersistence: PageBookmarkMutationsPersistence {

    func bookmarksPublisher() throws -> AnyPublisher<[MutatedPageBookmarkModel], Never> {
        fatalError("Not implemented")
    }

    func bookmarks() async throws -> [MutatedPageBookmarkModel] {
        fatalError("Not implemented")
    }

    func createBookmark(page: Int) async throws {
        fatalError("Not implemented")
    }

    func removeBookmark(page: Int) async throws {
        fatalError("Not implemented")
    }

    func clear() async throws {
        fatalError()
    }
}

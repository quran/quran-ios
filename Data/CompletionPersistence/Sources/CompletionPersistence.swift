//
//  CompletionPersistence.swift
//
//
//  Created by Selim on 29.03.2026.
//

import Combine
import Foundation

public protocol CompletionPersistence: Sendable {
    // Completions
    func completions() -> AnyPublisher<[CompletionPersistenceModel], Never>
    func insertCompletion(_ model: CompletionPersistenceModel) async throws
    func updateCompletion(_ model: CompletionPersistenceModel) async throws
    func deleteCompletion(id: UUID) async throws
    func setActive(id: UUID) async throws

    // Completion Bookmarks
    func completionBookmarks(completionId: UUID) -> AnyPublisher<[CompletionBookmarkPersistenceModel], Never>
    func allCompletionBookmarks() -> AnyPublisher<[CompletionBookmarkPersistenceModel], Never>
    func insertCompletionBookmark(_ model: CompletionBookmarkPersistenceModel) async throws
    func detachCompletionBookmark(id: UUID) async throws
}

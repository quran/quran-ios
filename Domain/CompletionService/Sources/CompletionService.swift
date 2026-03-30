//
//  CompletionService.swift
//
//
//  Created by Selim on 29.03.2026.
//

import Combine
import CompletionPersistence
import Foundation
import PageBookmarkPersistence
import QuranKit

public struct CompletionService {
    // MARK: Lifecycle

    public init(persistence: CompletionPersistence, pageBookmarkPersistence: PageBookmarkPersistence) {
        self.persistence = persistence
        self.pageBookmarkPersistence = pageBookmarkPersistence
    }

    // MARK: Public

    // MARK: - Completions

    public func completions(quran: Quran) -> AnyPublisher<[Completion], Never> {
        persistence.completions()
            .map { models in
                models
                    .filter { $0.quranId == quran.persistentId }
                    .map { Completion(quran: quran, $0) }
            }
            .eraseToAnyPublisher()
    }

    public func createCompletion(name: String?, quran: Quran) async throws -> Completion {
        let id = UUID()
        let model = CompletionPersistenceModel(
            id: id,
            name: name,
            quranId: quran.persistentId,
            startedAt: Date(),
            finishedAt: nil,
            isActive: false
        )
        try await persistence.insertCompletion(model)
        try await persistence.setActive(id: id)
        return Completion(id: id, name: name, quran: quran, startedAt: model.startedAt, finishedAt: nil, isActive: true)
    }

    public func renameCompletion(_ completion: Completion, to name: String) async throws {
        let updated = CompletionPersistenceModel(
            id: completion.id,
            name: name.isEmpty ? nil : name,
            quranId: completion.quran.persistentId,
            startedAt: completion.startedAt,
            finishedAt: completion.finishedAt,
            isActive: completion.isActive
        )
        try await persistence.updateCompletion(updated)
    }

    public func finishCompletion(_ completion: Completion) async throws {
        let updated = CompletionPersistenceModel(
            id: completion.id,
            name: completion.name,
            quranId: completion.quran.persistentId,
            startedAt: completion.startedAt,
            finishedAt: Date(),
            isActive: false
        )
        try await persistence.updateCompletion(updated)
    }

    public func deleteCompletion(_ completion: Completion) async throws {
        // Fetch all CompletionBookmarks for this completion to get page numbers
        let bookmarksPublisher = persistence.completionBookmarks(completionId: completion.id)
        let bookmarks = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CompletionBookmarkPersistenceModel], Error>) in
            var cancellable: AnyCancellable?
            cancellable = bookmarksPublisher.first().sink { models in
                continuation.resume(returning: models)
                _ = cancellable
            }
        }

        // Delete corresponding PageBookmarks
        for bookmark in bookmarks {
            try await pageBookmarkPersistence.removePageBookmark(bookmark.page)
        }

        // Delete the completion and all its CompletionBookmarks
        try await persistence.deleteCompletion(id: completion.id)
    }

    public func setActive(_ completion: Completion) async throws {
        try await persistence.setActive(id: completion.id)
    }

    public func progress(for completion: Completion) -> AnyPublisher<CompletionProgress, Never> {
        persistence.completionBookmarks(completionId: completion.id)
            .map { bookmarks in
                let pageNumbers = bookmarks.map { $0.page }
                let highestPageNumber = pageNumbers.max()
                let currentPage = highestPageNumber.flatMap { Page(quran: completion.quran, pageNumber: $0) }
                let pagesRead = currentPage?.pageNumber ?? 0
                let totalPages = completion.quran.pages.count

                var averageTimePerPage: TimeInterval?
                var estimatedFinishDate: Date?

                if pagesRead > 0 {
                    let elapsed = Date().timeIntervalSince(completion.startedAt)
                    let avg = elapsed / Double(pagesRead)
                    averageTimePerPage = avg
                    let pagesRemaining = totalPages - pagesRead
                    estimatedFinishDate = Date().addingTimeInterval(Double(pagesRemaining) * avg)
                }

                return CompletionProgress(
                    completion: completion,
                    totalPages: totalPages,
                    currentPage: currentPage,
                    pagesRead: pagesRead,
                    averageTimePerPage: averageTimePerPage,
                    estimatedFinishDate: estimatedFinishDate
                )
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Completion Bookmarks

    public func bookmarks(for completion: Completion) -> AnyPublisher<[CompletionBookmark], Never> {
        persistence.completionBookmarks(completionId: completion.id)
            .map { models in
                models.compactMap { CompletionBookmark(quran: completion.quran, $0) }
                    .sorted { $0.createdAt > $1.createdAt }
            }
            .eraseToAnyPublisher()
    }

    public func allCompletionBookmarks(quran: Quran) -> AnyPublisher<[CompletionBookmark], Never> {
        persistence.allCompletionBookmarks()
            .map { models in
                models.compactMap { CompletionBookmark(quran: quran, $0) }
            }
            .eraseToAnyPublisher()
    }

    public func addBookmark(page: Page, to completion: Completion) async throws {
        let model = CompletionBookmarkPersistenceModel(
            id: UUID(),
            completionId: completion.id,
            page: page.pageNumber,
            createdAt: Date()
        )
        try await persistence.insertCompletionBookmark(model)
    }

    public func removeBookmark(_ bookmark: CompletionBookmark) async throws {
        try await persistence.detachCompletionBookmark(id: bookmark.id)
    }

    // MARK: Private

    private let persistence: CompletionPersistence
    private let pageBookmarkPersistence: PageBookmarkPersistence
}

// MARK: - Quran Persistence Mapping

extension Quran {
    var persistentId: String {
        if self === Quran.hafsMadani1405 { return "hafsMadani1405" }
        if self === Quran.hafsMadani1440 { return "hafsMadani1440" }
        return "hafsMadani1405"
    }

    static func fromPersistentId(_ id: String) -> Quran {
        switch id {
        case "hafsMadani1440": return .hafsMadani1440
        default: return .hafsMadani1405
        }
    }
}

// MARK: - Model Mapping

private extension Completion {
    init(quran: Quran, _ model: CompletionPersistenceModel) {
        self.init(
            id: model.id,
            name: model.name,
            quran: quran,
            startedAt: model.startedAt,
            finishedAt: model.finishedAt,
            isActive: model.isActive
        )
    }
}

private extension CompletionBookmark {
    init?(quran: Quran, _ model: CompletionBookmarkPersistenceModel) {
        guard let page = Page(quran: quran, pageNumber: model.page) else { return nil }
        self.init(
            id: model.id,
            completionId: model.completionId,
            page: page,
            createdAt: model.createdAt
        )
    }
}
